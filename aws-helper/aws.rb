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
  puts "  list= verify if computing resources exists"
  puts "  create_admin=     Create admin resources. Admin bastion host and basic security groups"
  puts "  destroy_admin=    Destroy admin resources."
  puts "  create_volumes=   Create defined EBS volumes and format them using the bastion host."
  puts "  destroy_volumes=  Destroy defined EBS Volumes(will fail if they are still attached to host)"
  puts "  create=           Create infraestructre nodes and and load blancers defined."
  puts "  destroy=          Destroy all infrastructure nodes and load balances defined."
  puts "  start=            start all EC2 instances including bastion/admin host."
  puts "  stop=             stop  all EC2 instances inlcuding bastion/admin host."
  puts " Guidance: "
  puts " The normal use of the script will be this:"
  puts " To create the infra, execute in secuence: create_admin -> create_volumes -> create"
  puts " To create destroy all the infraestructure: destroy -> destroy_volumes -> destroy_admin"
  puts " To avoid cost when infra is not in use use start/stop as needed."
  puts " ......"
  puts " This is an experimental script use it with care. ;)"
end

$out_dir= Dir.pwd
ARGV.options do |opts|
  opts.on("-o", "--out-dir=val",String)        { |val| $out_dir= File.expand_path(val)  }
  opts.on_tail("-h", "--help")         		{ usage; exit 1}
  opts.parse!
end
$out_dir= $out_dir.strip.chomp("/")

if ARGV.length < 2 
  usage
	exit
end

# Reding the template
yml =  YAML.load(File.read(ARGV[0]))

# Main parameters
# Check https://coreos.com/os/docs/latest/booting-on-ec2.html
$region = yml["region"]

security_groups= (yml.key?("security_groups")) ? yml["security_groups"] : []
admin_security_groups= (yml.key?("admin_security_groups")) ? yml["admin_security_groups"] : []
admin_server= yml["admin_server"]
admin_server_name= admin_server["tags"]["Name"]
lservers = (yml.key?("servers")) ? yml["servers"] : []
volumes = (yml.key?("volumes")) ? yml["volumes"] : []
load_balancers = (yml.key?("load_balancers")) ? yml["load_balancers"] : []
$user_login= yml["user_name"]
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
	se=s_entry.dup
	name= se['tags']['Name']
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
											  write_files: wfiles
																			})
			#puts se["user_data"]
		end
	else
		puts "ERROR: undefined user data management... #{name} not created"
		return 
	end
	se.delete("user_data_type") if se.key?("user_data_type") # remove field
	se.delete("user_data_metadata") if se.key?("user_data_metadata") # remove field
	se.delete("write_files") if se.key?("write_files") # remove write_files

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
		File.write("#{$out_dir}/#{name}.txt", s.dns_name)
		File.write("#{$out_dir}/#{name}-userdata.yml",s.user_data)
		puts "State #{s.state}. #{s.dns_name} server created [#{name}.txt] file written"
		puts "User data writen to [#{name}-userdata.yml]"
	else
		puts "Server #{name} exists. nothing done."
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

else
	puts "#{ARGV[1]} verb not recognized. nothing done!"
end

