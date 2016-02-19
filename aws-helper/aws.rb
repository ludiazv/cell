#!/usr/bin/env ruby
require 'rubygems'
require 'fog'
require 'erubis'
require 'zlib'
require 'base64'
require 'open-uri'
require 'json'
require 'tunneler'
require 'optparse'

def usage
	puts "Bad usage. usage dev_aws.rb [options] <template file> <verb>"
  puts "  [options]"
  puts "  -o, --out-dir=<dir> directory to create output files when create or update infraestructure. defatul: current dir"
  puts " <template> a YML file with the infraestructure defintion. @see readme"
  puts " where <verb> is list|create|start|stop|destroy|create_admin|destroy_admin|create_volumes|destroy_volumes"
	puts "  							  create_elastic_ips|destroy_elastic_ips|create_storage|destroy_storage"
  puts "  list= verify if computing resources exists. also write files with server dns addresses"
  puts "  create_admin=        Create admin resources. Admin bastion host and basic security groups"
  puts "  destroy_admin=       Destroy admin resources."
  puts "  create_volumes=      Create defined EBS volumes and format them using the bastion host."
  puts "  destroy_volumes=     Destroy defined EBS Volumes(will fail if they are still attached to host)"
  puts "  create=              Create infraestructre nodes and and load blancers defined."
  puts "  destroy=             Destroy all infrastructure nodes and load balances defined."
  puts "  start=               start all EC2 instances including bastion/admin host."
  puts "  stop=                stop  all EC2 instances including bastion/admin host."
	puts "  create_elastic_ips=  Creates and attachd elastic ips defined"
	puts "  destroy_elastic_ips= Deattach and destroy elastic ips defined"
	puts "	create_storage=      Create S3 storages defined"
	puts "	destroy_storage=     Destroy S3 storages defined"
	puts " All resources are created/destroyed if defined in <template file>"
  puts " Guidance: "
  puts " The normal use of the script will be this:"
  puts " To create the infra, execute in secuence:  create_elastic_ips -> create_admin -> create_volumes -> create "
  puts " To create destroy all the infraestructure: destroy -> destroy_volumes -> destroy_admin -> destroy_elastic_ips"
	puts " Load blancers and storages can be created/destroyed anytime "
  puts " To avoid cost when infra is not in use use start/stop as needed."
  puts " ......"
  puts " This is an experimental script use it with care. ;)"
end

$out_dir= Dir.pwd
ARGV.options do |opts|
  opts.on("-o", "--out-dir=val",String)        { |val| $out_dir= File.expand_path(val)  }
  opts.on_tail("-h", "--help")         				 { usage; exit 0}
  opts.parse!
end
$out_dir= $out_dir.strip.chomp("/")

if ARGV.length < 2
  usage
	exit
end

if ! File.exists?(ARGV[0])
	puts "ERROR: Template file #{ARGV[0]} do not exists."
	exit 1
end

# Reding the template
print "Loading template file #{ARGV[0]}...."
yml =  YAML.load(File.read(ARGV[0]))
puts "loaded!"

# Main parameters
# Check https://coreos.com/os/docs/latest/booting-on-ec2.html
if !yml.key?("region") || !yml.key?("a_zone") || !yml.key?("admin_server") ||
	 !yml["admin_server"].key?("tags") || !yml["admin_server"]["tags"].key?("Name")

	 puts "ERROR: Malformed template #{ARGV[0]} it must contain the following entities:"
	 puts "region: valid AWS region"
	 puts "a_zone: valid AWS availability-zone within the region"
	 puts "admin_server: Valid defintion of an admin/bastion server"
	 puts "admin_server/tags/Name: name of the admin/bastion server"
	 exit 1
end

# Load resources with defaults
$region = yml["region"]
$zone= yml["a_zone"]
security_groups= (yml.key?("security_groups")) ? yml["security_groups"] : []
admin_security_groups= (yml.key?("admin_security_groups")) ? yml["admin_security_groups"] : []
admin_server= yml["admin_server"]
admin_server_name= admin_server["tags"]["Name"]
lservers = (yml.key?("servers")) ? yml["servers"] : []
volumes = (yml.key?("volumes")) ? yml["volumes"] : []
load_balancers = (yml.key?("load_balancers")) ? yml["load_balancers"] : []
elastic_ips = (yml.key?("elastic_ips")) ? yml["elastic_ips"] : []
s3_storages= (yml.key?("s3_storages")) ? yml["s3_storages"] : []
$user_login= (yml.key?("user_name")) ? yml["user_name"] : "core"
$key_path= yml["key_file"]

# Loading machine types from coreOs Feed
puts "Reading https://coreos.com/dist/aws/aws-stable.json ami types..."
content = open("https://coreos.com/dist/aws/aws-stable.json").read
ami_types= JSON.parse(content)
if ami_types.nil? || !ami_types.is_a?(Hash) || !ami_types.key?('release_info') ||
   !ami_types['release_info'].key?('version') || !ami_types.key?($region)
   puts "Could not retrieve stable coreos feed fro ami type automation."
   puts "#{content}"
   exit 1
else
  puts "Using CoreOs version:#{ami_types['release_info']['version']} with for region #{$region}"
  puts "Automated AMIS in use => #{ami_types[$region]}"
end
$amis=ami_types[$region]

# key functions
def dump_subnet(c,zone=$zone)

  c.subnets.all({'availability-zone'=> zone}).each_with_index do |subnet,i|
    puts "Subnet id:#{subnet.subnet_id} on VPC:#{subnet.vpc_id} with CIRD:#{subnet.cidr_block} free addresses:#{subnet.available_ip_address_count}"
    File.write("#{$out_dir}/#{zone}-cidr-#{i}.txt",subnet.cidr_block)
    puts "File #{$out_dir}/#{zone}-cidr-#{i}.txt with subnet range #{subnet.cidr_block} created!"
  end

end

def find_security_group(c,sg_name)
	c.security_groups.get(sg_name)
end

def find_server(c,server_name)
	c.servers.all({"tag:Name"=>server_name}).each do |r|
		sleep 15 if r.state == "shutting-down"
		return r if (r.state!="terminated" && r.state!="shutting-down")
 	end
 	nil
end

def ssh_server(s,cmd)
	s.username=$user_login
	s.private_key_path=$key_path
	s.ssh(cmd)
end

def ssh_thru_bastion(bastion_host,internal_host,cmd)
  # Create SSH tunnel
  tunnel = Tunneler::SshTunnel.new($user_login, bastion_host, {:keys => [$key_path]})
  remote = tunnel.remote($user_login, internal_host, {:keys => [$key_path]})
  response = remote.ssh(cmd)
  tunnel.terminate
  #puts response
  response
end

def find_load_balancer(c,lb_name)
  connection.load_balancers.get(lb_name)
end

def destroy_load_balancer(c,lb_name)
	ebl = c.load_balancers.get(lb_name)
	if ebl.nil?
		puts "#{lb_name} does not exists, nothing done!"
	else
		puts "Detroy:#{lb_name} -> #{elb.destroy}"
	end
end

def create_load_balancer(c,lb)
  elb=find_load_balancer(c,lb["name"])
  if elb.nil?
    name=lb["name"]
    # create
    result = c.create_load_balancer(lb["availability_zones"], name, lb["listeners"])
    if result.status != 200
      puts "ELB creation failed!"
      return nil
    end
    result = c.configure_health_check(name, lb["healt_check"])

    if result.status != 200
      puts "ELB Failed health check configuration request"
      return nil
    end
    elb=find_load_balancer(name)
    puts "LB #{elb.inspect} configured."
  else
    puts "Load Balancer #{lb["name"]} exists, nothing done!"
  end
end

def find_volume(c,v_name)
	c.volumes.all({"tag:Name" => v_name}).first
end

def string_to_range(s)
	ends = s.split('..').map{|d| Integer(d)}
	ends[0]..ends[1]
end

def create_security_group(c,s_g)
	sg=find_security_group(c,s_g['name'])
	(puts "SG:#{s_g['name']} exists! not created!"; return false) if !sg.nil?
	print "Creating Security group:#{s_g['name']}."
	scd= s_g.dup; scd.delete('rules')
	sg= c.security_groups.new(scd)
	puts ".Saved: #{sg.save} Rules ->"
	r=nil

	s_g['rules'].each do |rule|
		case rule['org_type']
		when "group"
			a=c.security_groups.get(rule['org_data']) # get the sg authorized
			r= sg.authorize_port_range(string_to_range(rule['port_range']),
				                         {:group => { a.owner_id => a.group_id}, :ip_protocol => rule['protocol']})
		when "ip"
			r= sg.authorize_port_range(string_to_range(rule['port_range']), {:cidr_ip => rule['org_data'],
				                          	:ip_protocol => rule['protocol']} )
		else
			puts "Error: #{s_g['name']} could not be create propely -> #{rule}"
		end

		if r.nil? || r.status != 200
			puts "Error: #{rule['org_type']} gate:#{rule['protocol']}:#{rule['port_range']} to #{rule['org_data']} couldn't not be created!"
		else
			puts "#{rule['org_type']} gate:#{rule['protocol']}:#{rule['port_range']} to #{rule['org_data']} created!"
		end
	end
	true
end

def destroy_security_group(c,name)
		sg = c.security_groups.get(name)
		if sg.nil?
			puts "#{name} does not exists, nothing done!"
		else
			puts "Detroy:#{name} -> #{sg.destroy}"
		end
end

def create_volume(c,vol,admin_server_name="admin")
	vol_name=vol['tags']['Name']
	v=find_volume(c,vol_name)
	if v.nil?
		# find server admin for formating
		s= find_server(c,admin_server_name)
		if !s.nil?
			print "Creating volumen #{vol_name}."
			vol['server_id']=s
			v=c.volumes.new(vol)
			v.server = s
			v.save
			v.wait_for { print "."; state=="in-use"}
			print "state: #{v.state}...Formating ..."
			format_cmd= vol['format_cmd']
			res=ssh_server(s,format_cmd)
			puts "Result:"
			res.each { |r| puts "status:#{r.status}\nstdout:\n#{r.stdout}\nstderr:#{r.stderr}" }
			v.reload
			v.server=nil

		else
			puts "ERROR: volume #{vol_name} not create as server #{vol['server_id']} do not exits!"
		end
	else
		puts "Volumen #{vol_name} exitis #{v.state}, nothing done!"
	end
end

def destroy_volume(c,name)
	v=find_volume(c,name)
	if v.nil?
		puts "Volumen do not exitis or in-use #{v}, nothing done."
	else
		if v.state == "in-use"
			print "Detaching..."
			v.server=nil
			v.wait_for { print "."; state=="available"}
		end
		puts "Revome volume:#{name} -> #{v.destroy}"; sleep 2
	end
end

def destroy_server(c,name)
	sd=find_server(c,name)
	if sd.nil?
		puts "Server #{name} does not exists. nothing done."
	else
	    print "Removing Server #{name} ."
	    id= sd.id
	    print "result:#{sd.destroy}"
	    sd.wait_for { print "."; state=="terminated" }
	    puts " State: #{sd.state}"
	end
end

def create_server(c, s_entry,admin_server_name="admin")
  # init locals
	se=s_entry.dup
	name= se['tags']['Name']
	elastic_ips=[]
	effective_elastic_ip=[]

	# Automatic AMI selection
  if se.key?('image_type') && $amis.key?(se['image_type'])
    se['image_id']= $amis[se['image_type']]
  end
  se.delete 'image_type' if se.key?('image_type')
	# Process templates and tranform entry
	case se["user_data_type"]
	when "file"
		se["user_data"] =File.read(se["user_data"])
	when "template"
		template=Erubis::Eruby.new(File.read(se["user_data"]))
		# find admin server
		as= find_server(c,admin_server_name)
		if as.nil? && name!=admin_server_name
			puts "ERROR: user data needs admin server #{name} not created"
			return
		else
			adm_ip = (as.nil?) ? "$private_ipv4" : as.private_ip_address
			wfiles= (se.key?('write_files')) ? se['write_files'].dup : []
			wfiles.each do |f|
				#f['base64']= Base64.encode64(Zlib::Deflate.deflate(File.read(f['file']))).gsub(/\n/, '')
				f['base64'] = File.read(f['file']).strip.gsub('\n','').gsub('\r','')
			end
			se["user_data"]= template.result({admin_serverip: adm_ip,
											  metadata: se["user_data_metadata"],
											  swap_size: se['swap_size'],
											  write_files: wfiles ,
												params: (se.key?('user_data_params')) ? se['user_data_params'] : {} })
			#puts se["user_data"]
		end
	else
		puts "ERROR: undefined user data management... #{name} not created"
		return
	end
	se.delete("user_data_type") if se.key?("user_data_type") # remove field
	se.delete("user_data_metadata") if se.key?("user_data_metadata") # remove field
	se.delete("write_files") if se.key?("write_files") # remove write_files

	# processing suitable Elastic_ip creation
	if se.key?('associate_elastic_ip') && se['associate_elastic_ip'].is_a?(Array) &&
		 !se['associate_elastic_ip'].empty?
		c.addresses.all.each { |e| elastic_ips << e} # Get all elastic IPS
		se['associate_elastic_ip'].each do |index|
			 effective_elastic_ip << elastic_ips[index] if (elastic_ips.length-1)> index
		end
	end
	se.delete('associate_elastic_ip') if se.key('associate_elastic_ip')
	# Create server
	print "Creating server #{name}."
	if find_server(c,name).nil?
		s=c.servers.create(se)
		if !s.nil?
			s.wait_for { print "."; ready? }
		else
			puts "ERROR: server #{name }not created!"
			return
		end
		s.reload
		effective_elastic_ip.each do |addr|
				r=c.associate_address(s.id, addr.public_ip)
				print "[Elastic IP #{addr.public_ip} -> #{r} associated]"
		end
		File.write("#{$out_dir}/#{name}.txt", s.dns_name)
		File.write("#{$out_dir}/#{name}-userdata.yml",s.user_data)
		puts "State #{s.state}. #{s.dns_name} server created [#{name}.txt] file written"
		puts "User data writen to [#{name}-userdata.yml]"

	else
		puts "Server #{name} exists. nothing done."
	end

end

def create_elastic_ip(c,domain)
		eip=c.allocate_address(domain)
		if eip.status != 200
			puts "ERROR: Elastic_ip could not be created #{eip.inspect}"
		else
			puts "Elastic IP created [#{eip.body['domain']}] #{eip.body['publicIp']}/#{eip.body['allocationId']}"
		end
end

def destroy_elastic_ip(c,ip)
		puts "TODO"
end

def create_storage(c,s3)
	return nil if !s3.is_a?(Hash) || !s3.key?('key')
	s=c.directories.get(s3['key'])
	if !s.nil?
		puts "Storage #{s3['key']} already exists -> nothing done!"
	else
		# hack save &
		#dr=Fog::Storage::AWS::DEFAULT_REGION; Fog::Storage::AWS::DEFAULT_REGION=$region
		s3['location']=$region unless s3.key?('location')
		s=c.directories.create(s3)
		#dir.location=$region
		#puts dir.location
		#puts dir.pretty_inspect
		#puts dir.methods
		#puts dir.persisted?
		#puts dir.public_url
		#dir.instance_variables.map{|var| puts [var, dir.instance_variable_get(var)].join(":")}
		#service=dir.instance_variable_get("@service")
		#acl=dir.instance_variable_get("@acl")
		#service.put_bucket(s3['key'], {'x-amz-acl'=> acl,'LocationConstraint'=> dir.location})
		#s=c.directories.get(s3['key'])
		puts "#{s3['key']} s3 storage -> #{s.public_url} "
		#Fog::Storage::AWS::DEFAULT_REGION=dr
	end
	s
end

def destroy_storage(c,s3)
	return nil if !s3.is_a?(Hash) || !s3.key?('key')
	s=c.directories.get(s3['key'])
	if s.nil?
		puts "S3 storage #{s3['key']} do not exists -> nothing done!"
	else
		files=s.files.map{ |file| file.key }
		(puts "Removing #{files.length} files"; c.delete_multiple_objects(s3['key'], files) ) unless files.empty?
		puts "Destroy S3 storage #{s3['key']} -> #{s.destroy}"
	end

end

if !ENV.key?('AWS_ACCESS_KEY') || !ENV.key?('AWS_SECRET_ACCESS_KEY')
  puts "Error:AWS keys not defined as env variables. Must set AWS_ACCESS_KEY & AWS_SECRET_ACCESS_KEY"
  exit 1
end

com = Fog::Compute.new({provider: "AWS",
						aws_access_key_id: ENV['AWS_ACCESS_KEY'],
						aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
						region: $region })

com_st= Fog::Storage.new({provider: "AWS",
						aws_access_key_id: ENV['AWS_ACCESS_KEY'],
						aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
						region: $region })

case ARGV[1]
when "create_admin"
	# Assure that security groups exists
  admin_security_groups.each do |sg|
	  create_security_group(com,sg)
  end
	# Create server.
	create_server(com,admin_server,admin_server['tags']['Name'])

when "destroy_admin"
	destroy_server(com,admin_server_name) # Destroy server first
  #destroy security groups in reverse order
  admin_security_groups.reverse.each do |sg|
	  destroy_security_group(com,sg['name'])
  end

when "create_volumes"
	volumes.each do |v|
		create_volume(com,v,admin_server_name)
	end

when "destroy_volumes"
	volumes.each do |v|
		destroy_volume(com,v['tags']['Name'])
	end

when "list"
  # Print all admin resources
  puts "Admin Security groups..."
  admin_security_groups.each do |sg|
    next unless sg.key?('name')
    g=find_security_group(com,sg['name'])
    puts "#{sg['name']} => #{(g.nil?) ? 'not pressent' : g.description}"
  end
  puts "Security groups..."
  security_groups.each do |sg|
    next unless sg.key?('name')
    g=find_security_group(com,sg['name'])
    puts "#{sg['name']} => #{(g.nil?) ? 'not pressent' : g.description}"
  end
  puts "Admin server..."
  as=find_server(com,admin_server['tags']['Name'])
  if !as.nil?
    puts "#{admin_server['tags']['Name']} => #{as.inspect}"
		File.write("#{$out_dir}/#{as.tags['Name']}.txt", as.dns_name)
		puts "State #{as.state}. #{as.dns_name} server created [#{admin_server['tags']['Name']}.txt] file written"
  end
  puts "Node servers..."
  lservers.each do |ser|
    s=find_server(com,ser['tags']['Name'])
    if !s.nil?
      puts "#{ser['tags']['Name']} => #{s.inspect}"
      File.write("#{$out_dir}/#{s.tags['Name']}.txt", s.dns_name)
      puts "State #{s.state}. #{s.dns_name} server created [#{s.tags['Name']}.txt] file written"
    end
  end
  puts "Volumes..."
  puts "Not implemented."
  puts "Load Balancers..."
  puts "TODO- Not implemented"
	puts "Elastic IPs..."
	com.addresses.all.each do |ip|
			puts "Elastic ip [#{ip.domain}]#{ip.public_ip} on server: #{ip.server_id} "
	end
	puts "S3 Storages...."
	s3_storages.each do |s3|
		s3s=com_st.directories.get(s3['key'])
		if s3s.nil?
			puts "Storage bucket #{s3['key']} do not exists."
		else
			puts "Storage bucket #{s3['key']} -> #{s3s.location}"
		end
	end
  puts "Query region[#{$region}/#{$zone}] subnet.."
  dump_subnet(com)

	#com.security_groups.each do |ss|
	#	puts ss.inspect
	#end
	#com.servers.all({"tag:Name"=>"test-admin"}).each do |s|
	#	puts s.inspect
	#end

when "create"
	# Creating security groups
	puts "Creting security groups...."
	security_groups.each do |sc|
		create_security_group(com,sc)
	end
	puts "Security groups done!"
  puts "Creating Load Balancers..."
  load_balancers.each do |elb|
    create_load_balancer(com,elb)
  end
  puts "Load Balancers done!"
	puts "Creating instances ...."
	lservers.each do |sr|
		create_server(com,sr,admin_server_name)
	end
	puts "Attaching volumes..."
  as= find_server(com,admin_server_name)
  if as.nil?
    puts "ERROR: #{admin_server_name} could not be found volumes could not be mounted!"
    exit 1
  end
	lservers.each do |sr|
		volumes.each do |vol|
			v=find_volume(com,vol['tags']['Name'])
			if !v.nil? && vol['server_id'] == sr['tags']['Name']
				s= find_server(com,vol['server_id'])
				if !s.nil?
          if s.id == v.server_id
            puts "Volume #{vol['tags']['Name']} is already attached to #{sr['tags']['Name']}... nothing done!"
            next
          end
          if v.state == 'in-use'
            puts "Volume #{vol['tags']['Name']} is already in use to server #{v.server_id} .. nothing done!"
            next
          end
					puts "Attaching volume... #{vol['tags']['Name']} to #{sr['tags']['Name']}"
					v.device = vol['device']
					v.server = s
          if !vol.key?('mount_cmd')
            puts "Volume has not mount_cmd defined. It can't be mounted."
            next
          end
          puts "Give some time (60s) to the manchine to boot...."; sleep 60
          puts "Mounting #{vol['tags']['Name']} in #{sr['tags']['Name']}..."
          puts "result:#{ssh_thru_bastion(as.dns_name,s.private_ip_address,vol['mount_cmd'])}"
				end
			end
		end
	end
	puts "Servers done!"

when "destroy"
	puts "Removing servers ..."
	lservers.each do |sr|
		destroy_server(com,sr['tags']['Name'])
	end
	puts "Remove servers done!"
  puts "Remove load balancers ..."
  load_balancers.each do |elb|
    destroy_load_balancer(com,elb['name'])
  end
  puts "Remove load balacers done!"
	# Destroy all security groups
	puts "Removing security groups...."
	security_groups.reverse.each do |sc|
		destroy_security_group(com,sc['name'])
	end
	puts "Security groups done!"
	# Destroy all instances

when "start"
	puts "Starting all servers..."
	([admin_server]+lservers).each do |ser|
		s=find_server(com,ser['tags']['Name'])
	  (puts "Server #{ser['tags']['Name']} not found!"; next) if s.nil?
    (puts "Server #{ser['tags']['Name']} is running!"; next) if s.state == "running" || s.state=="pending"
	  print "Starting #{s.tags['Name']}..."
    s.start
		s.wait_for { print "."; ready? }
		s.reload
    name=s.tags['Name']
		File.write("#{$out_dir}/#{name}.txt", s.dns_name)
		#File.write("#{$out_dir}/#{name}-userdata.yml",s.user_data)
		puts "State #{s.state}. #{s.dns_name} server created [#{name}.txt] file written"
		#puts "User data writen to [#{name}-userdata.yml]"
  end

when "stop"
	puts "Stopping all servers..."
	([admin_server]+lservers).each do |ser|
    s=find_server(com,ser['tags']['Name'])
	  (puts "Server #{ser['tags']['Name']} not found!"; next) if s.nil?
    (puts "Server #{ser['tags']['Name']} is stoped!"; next) if s.state == "stopped" || s.state=="stopping"
	  puts "Stoping #{s.tags['Name']}..."
    s.stop
  end

when "create_elastic_ips"
	puts "Creating Elastic IPs..."
	elastic_ips.each do |e_ip|
		create_elastic_ip(com,e_ip)
	end
when "destroy_elastic_ips"
	puts "Destroy elastic IPs..."
	puts "Destroy elastic ips..."
	puts "TODO"

when "create_storage"
	puts "Creating S3 storage for region #{com_st.region}..."
	s3_storages.each do |s3|
		s3t=s3.dup;
		s3t.delete('upload_files') if s3t.key?('upload_files')
		s3s=create_storage(com_st,s3t)
		if !s3s.nil? && s3.key?('upload_files') &&
			 s3['upload_files'].is_a?(Array)
			puts "Uploading files..."
			s3['upload_files'].each do |file|
				if file.key?('body_file')
					file['body']=File.open(file['body_file'])
					file.delete('body_file')
				end
				print "[#{s3s.files.create(file).key}]"
			end
			puts "!"
		end
	end

when "destroy_storage"
	puts "Destroying S3 storage..."
	s3_storages.each do |s3|
		destroy_storage com_st, s3
	end

else
	puts "#{ARGV[1]} verb not recognized. nothing done!"
end
exit 0
