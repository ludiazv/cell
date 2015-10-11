#!/usr/bin/env ruby
#/ Usage: etcd-yaml [options] import|export|delete
#/ import: yml -> ectd | export: etcd -> export  | delete: delete prefix (default: export)
#/ -f , --file="filename" input/output file (default: stdin/stdout will be used)
#/ -C , --endpoint="etcdendpoint" etcd endpoint (default: http://127.0.0.1:2397 )
#/ -k , --keyfile="filename" key file use when encrypting/decrypting keys. import requires a public key.
#/ -p , --prefix="prefix" prefix to use within etcd. When importing will be added to all keys, when exporting will be used as root key. (default: /)
#/ -y , --yes Assume yes for interective questions.
#/ -r , --recursive use recursive delete.
#/ -t , --tunnel="" should be in the format ssh://user[:password]@addr[:port] (default: no tunnel)
#/ For using etcd-yaml-crtyp functions gpg2 and gzip **MUST** be installed on the system.

$stderr.sync = true
require 'rubygems'
require 'optparse'
require 'uri'
require 'etcd'
require 'yaml'
require 'base64'
require 'net/ssh/gateway'



# Import queue
$push_q =[]
$net_gateway= nil

# default options
endpoint    	= "http://127.0.0.1:2379"
filename    	= nil
keyfile      	= ".public.gpg"
prefix 			= "/"
action			= "export"
ask_to_import 	= true
tunnel_to		= nil
recursive_delete= false
mIO = nil


# Functions
def add_yml_to_hash(current,nd)
	if nd.is_a?(Hash)
		current.merge(nd) do |k,v1,v2|
			if v1.is_a?(Hash) && v2.is_a?(Hash)
			    add_yml_to_hash(v1,v2)
			else
				v2
			end
		end
	else
		current
	end

end

def export_etcd(ecli,base_path,info_hash={})
	info= ecli.get base_path
	#print "got #{base_path} "
	if !info.nil?
		sub_keys= base_path.split('/')
		simple_key= sub_keys.last
		simple_key= "/" if simple_key.nil?
		if info.directory?
			info_hash["#{simple_key}"] = {}
			info.children.each do |c|
				sub_keys = c.key.split('/')
				simple_key_child = sub_keys.last
				cl= export_etcd(ecli,"#{c.key}")
				info_hash["#{simple_key}"]["#{simple_key_child}"] = cl["#{simple_key_child}"]
			end
		else
			info_hash["#{simple_key}"] = info.value
		end
	else
		puts "ERROR: Could not retrieve #{base_path}"
		info_hash = nil
	end
	info_hash
end

def req_keyfile?(data)
	r= false
	if data.is_a?(Hash)
		data.each do |k,v|
			#puts "#{k} -> #{k =~ /etcd_yaml_crypt_.+/}"
			return true if k =~ /etcd_yaml_crypt_.+/
			(r = r || req_keyfile?(v)) if v.is_a?(Hash)
		end
	end
	r
end

def import_crypt_keyfile(file)
	print "Crypt required importing key #{file}:"
	res = %x(gpg2 --import #{file} 2>&1)
	if $? == 0 
		r=res[/^gpg:\skey\s([A-Z0-9]+):.*/,1]
		puts "OK ID:#{r}"
		r
	else
		puts "failed loading #{file}."
		nil
	end
end
def remove_cryp_keyfile(key_id)
	print "Removing key ID:#{key_id}..."
	%x(gpg2 --batch --yes --delete-key #{key_id})
	ok= ($? == 0)
	puts (ok) ? "OK" : "failed!"
	ok
end

def crypt(val,id)
	cmd="echo \"#{val}\" | gzip -9 | gpg2 --compress-algo none --batch --yes --trust-model always -e --output -  -r #{id}"
	res=%x(#{cmd})
	($? == 0) ? Base64.strict_encode64(res) : nil
end

def push_etcd(ecli)
	$push_q.each do |e|
		print "."
		ecli.set e[:path], value: e[:value]
	end
end

def import_etcd(ecli,base_path,data,key_id)
	if data.is_a?(Hash)
		data.each do |k,v|
			base_t= (base_path[-1]=="/") ? base_path[0..-2] : base_path
			import_etcd ecli,"#{base_t}/#{k}",v,key_id
		end
	else
		
		v= data
		k= base_path
		if base_path =~ /etcd_yaml_crypt_.+/
			v= crypt(data,key_id); 
			k=k.gsub('etcd_yaml_crypt_','') 
		end
		if base_path =~ /etcd_yaml_fileplain_.+/
			v= File.read(data); 
			k=k.gsub('etcd_yaml_fileplain_','') 
		end
	    if base_path =~ /etcd_yaml_file_.+/
			v= Base64.strict_encode64(File.read(data)); 
			k=k.gsub('etcd_yaml_file_','') 
		end
		if base_path =~ /etcd_yaml_key_.+/
			v= ecli.get v;
			v= v.value if !v.nil? 
			k=k.gsub('etcd_yaml_key_','') 
		end
		if v.nil?
			puts "error could not decode!"
			exit 4
		else
			$push_q << {path: k, value: v }
		end
	end
end


# parse arguments
file = __FILE__
ARGV.options do |opts|
  opts.on("-f", "--file=val",String)        { |val| filename= val  }
  opts.on("-C", "--endpoint=val", String)   { |val| endpoint = val }
  opts.on("-p", "--prefix=val", String)  	{ |val| prefix = val }
  opts.on("-k", "--keyfile=val", String)	{ |val| keyfile= val }
  opts.on("-y", "--yes")					{ ask_to_import = false }
  opts.on("-t", "--tunnel=val",String)		{ |val| tunnel_to = val}
  opts.on("-r", "--recursive")				{ recursive_delete = true }
  opts.on_tail("-h", "--help")         		{ exec "grep ^#/<'#{file}'|cut -c4-" }
  opts.parse!
end

# do your thing

action = ARGV[0] if ARGV.any?

# Set-up etcd conection
endpoint_uri=URI.parse(endpoint)
host = endpoint_uri.host
port = endpoint_uri.port
if endpoint_uri.scheme !="http" || host.nil?
	puts "ERROR: Endpoint '#{endpoint}' is not valid. Check format 'http://addr:port'."
	exit 1
end
port= 2379 if port.nil?

# Set-up tunnel if requested
if !tunnel_to.nil?
	tunnel_uri= URI.parse(tunnel_to)
	if tunnel_uri.nil? || tunnel_uri.scheme !="ssh" || tunnel_uri.host.nil? || tunnel_uri.user.nil?
		puts "ERROR: Tunnel #{tunnel_to} is not valid. Check format ssh://user[:password]@addr[:port]."
		exit 1
	end
	tunnel_options={}
	tunnel_options[:port] = tunnel_uri.port if !tunnel_uri.port.nil?
	tunnel_options[:password]= tunnel_uri.password if !tunnel_uri.password.nil?
	$net_gateway = Net::SSH::Gateway.new(tunnel_uri.host,tunnel_uri.user,tunnel_options)
	$gateway_port = $net_gateway.open(host,port)
	host="127.0.0.1" # chage to local
	port=$gateway_port	
end

# Set up and check etcd client
etcd_client=  Etcd.client(host: host, port: port)
etcd_version =etcd_client.version

case action.downcase
when "import"
	puts "Importing into etcd #{endpoint} on #{prefix}"
	mIO = (filename.nil?) ? $stdin : File.open(filename,"r")
	if mIO.nil?
		puts "ERROR: Couldn't open file #{filename}"
		exit 2
	end
	data = YAML::load(mIO.read)
	# merge includes
	if data.key?('etcd_yaml_include') && data['etcd_yaml_include'].is_a?(Array)
		data['etcd_yaml_include'].each do |f|
			data=add_yml_to_hash(data,YAML::load(File.read(f))) if File.exists?(f)
		end
		data.delete('etcd_yaml_include')
	end

	if data.is_a?(Hash)
		req= req_keyfile?(data)

		if req && !File.exists?(keyfile)
			puts "ERROR: keyfile #{keyfile} required but not exists"
			exit 4
		end
		if ask_to_import
			print "Import ready do you want to continue [Y/n]?"
			r=$stdin.readline()
			exit 0 if r.downcase!="y"
		end
		key_id=nil
		key_id=import_crypt_keyfile keyfile if req
		puts "Econding...."
		import_etcd etcd_client,prefix,data,key_id
		remove_cryp_keyfile key_id if req && !key_id.nil?
		print "loading etcd."; push_etcd etcd_client; puts "!"
	else
		puts "ERROR: YML is not a hash or contains format errors."
		exit 3
	end 

when "export"
	# do export
	mIO = (filename.nil?) ? $stdout : File.open(filename,"w")
	if mIO.nil?
		puts "ERROR: Couldn't open file #{filename}"
		exit 2
	end
	data = export_etcd etcd_client, prefix
	if data.nil? || !data.is_a?(Hash)
			puts "ERROR: Retriving key => #{prefix}"
			exit 3
	else
		# data['etcd-yaml-prefix'] = prefix 
		mIO.write "# -- Extracted by etcd-yaml at #{Time.now.utc}\n"
		mIO.write "# -- #{etcd_version} --\n"
		#mIO.write "etcd-yaml-prefix: #{prefix}\n\n"
		mIO.write data.to_yaml
		mIO.sync
	end

when "delete"
	print "Deleting #{prefix}.."
	if ask_to_import
		print "Import ready do you want to continue [Y/n]?"
		r=$stdin.readline().chomp
		exit 0 if r.downcase!="y"
	end
	puts etcd_client.delete prefix, (recursive_delete) ? {recursive: true} : {}
	puts "#{prefix} cleaned!"

when "version"
	puts "0.1"

else
	puts "Action #{action} not recognized. try etcd-yaml.rb --help"
	exit 1
end

$net_gateway.close($gateway_port); $net_gateway.shutdown! if !$gateway.nil? && !$gateway_port.nil?


