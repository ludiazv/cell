#!/usr/bin/env ruby
require 'rubygems'
require 'fog'
require 'erubis'
require 'zlib'
require 'base64'

if ARGV.length ==0 
	puts "Bad usage. usage dev_aws.rb list|create|start|stop|destroy|create_admin|destroy_admin|create_volumes|destroy_volumes"
	exit
end

# Reding test.yml
yml =  YAML.load(File.read("test.yml"))

# Main parameters
# Check https://coreos.com/os/docs/latest/booting-on-ec2.html
region = yml["region"]

security_groups= yml["security_groups"]
admin_server= yml["admin_server"]
admin_server_name= admin_server["tags"]["Name"]
lservers = (yml.key?("servers")) ? yml["servers"] : []
volumes = (yml.key?("volumes")) ? yml["volumes"] : []
load_balancers = (yml.ke?("load_balancers")) ? yml["load_balancers"] : []
$user_login= yml["user_name"]
$key_path= yml["key_file"]

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
			wfiles= se['write_files'].dup
			wfiles.each do |f| 
				#f['base64']= Base64.encode64(Zlib::Deflate.deflate(File.read(f['file']))).gsub(/\n/, '')
				f['base64'] = File.read(f['file'])
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
		File.write("#{name}.txt", s.dns_name)
		File.write("#{name}-userdata.yml",s.user_data)
		puts "State #{s.state}. #{s.dns_name} server created [#{name}.txt] file written"
		puts "User data writen to [#{name}-userdata.yml]"
	else
		puts "Server #{name} exists. nothing done."
	end

end


com = Fog::Compute.new({provider: "AWS",
						aws_access_key_id: ENV['AWS_ACCESS_KEY'],
						aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
						region: region })

case ARGV[0] 
when "create_admin"
	# Assure that security groups exists
	create_security_group(com,security_groups[0])
	create_security_group(com,security_groups[1])
	create_security_group(com,security_groups[2])
	# Create server.
	create_server(com,admin_server,admin_server['tags']['Name'])
	
when "destroy_admin"
	destroy_server(com,admin_server_name)
	destroy_security_group(com,security_groups[2]['name'])
	destroy_security_group(com,security_groups[1]['name'])
	destroy_security_group(com,security_groups[0]['name'])

when "create_volumes"
	volumes.each do |v|
		create_volume(com,v,admin_server_name)
	end
when "destroy_volumes"
	volumes.each do |v|
		destroy_volume(com,v['tags']['Name'])
	end

when "list"
	# Printing 
	#com.servers.each do |s|
	#	puts s.inspect
	#end

	#com.security_groups.each do |ss|
	#	puts ss.inspect
	#end 
	com.servers.all({"tag:Name"=>"test-admin"}).each do |s|
		puts s.inspect
	end

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
	lservers.each do |sr|
		volumes.each do |vol|
			v=find_volume(com,vol['tags']['Name'])
			if !v.nil? && vol['server_id'] == sr['tags']['Name']
				s= find_server(com,vol['server_id'])
				if !s.nil?
					puts "Attaching volume... #{vol['tags']['Name']} to #{sr['tags']['Name']}"
					v.device = vol['device']
					v.server = s
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
	security_groups.delete_at(0); security_groups.delete_at(0); security_groups.delete_at(0)
	security_groups.reverse.each do |sc| 
		destroy_security_group(com,sc['name'])
	end
	puts "Security groups done!"
	# Destroy all instances


when "start"
	puts "Starting all servers..."
	#[admin_server_name,*lservers].each do |s_name|
	#	s=find_server(com,s_name)
	#	if !s.nil? && s.state != "running" 
	#		print "Starting s.tags['Name']"
	#		s.start



when "stop"
	puts "Stopping all servers..."
	#lservers.each do |s_name|
	#
	#end

else
	puts "#{ARGV[0]} verb not recognized. nothing done!"
end

#com.servers.each do |s|
#	puts s.inspect
#	if s.tags.key?('Name') && srv.include?(s.tags['Name'])
#			puts "#{ARGV[0]} of #{s.tags['Name']}"
			#s.start if ARGV[0]=="start"
			#s.stop if ARGV[0]=="stop"
			#s.destroy if ARGV[0]=="destroy"
#	else
#		if s.tags.key?('Name') 
#	   		puts "Do nothing with .. #{s.id} [#{s.state}]-> #{s.tags['Name']}"
#	   	else
#	   		puts "Do nothing with ... #{s.id} [#{s.state}]"
#	   	end
#	end
#end
