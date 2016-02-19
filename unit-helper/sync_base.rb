#!/usr/bin/env ruby
#/ Usage: deploy_base [options] environment
#/ -m , --manifest="filename" use other file than manifest.yml
#/ -C, --endpoint="addr[:port]" fleet endpoint used with fleetctl (default: 127.0.0.1:)
#/ -y , --yes Assume yes for interective questions.
#/ -t , --tunnel="ssh-uri" should be in the format ssh://user[:password]@addr[:port] (default: no tunnel)
#/ -s , --tunnel-key="file" if ssh is autheticated this is the file with ssh identity. If given any provided password is not used. (default: no tunnel)
#/ -f , --clean Perform cleaning of units stop, unload, destroy only
#/ Disclaimer:
#/ 1. For using etcd-yaml-crtyp functions gpg2 and gzip **MUST** be installed on the system.
#/ 2. If --tunnel option is provided with --tunnel-key identities available in ssh-agent will not be used.
#/ -n, --stop will stop all services running before
#/ For using etcd-yaml-crtyp functions gpg2 and gzip **MUST** be installed on the system.

$stderr.sync = true
require 'rubygems'
require 'optparse'
require 'uri'
require 'net/ssh/gateway'
require_relative 'coreos_unit_helper.rb'


# Defaults
manifest_file ="manifest.yml"
ask_to_advance = true
tunnel_to   = nil
tunnel_key  = nil
endpoint= "http://127.0.0.1:2379"
clean_only=false

# parse arguments
file = __FILE__
script_path= File.expand_path('..', file)

ARGV.options do |opts|
  opts.on("-m", "--manifest=val",String)        { |val| manifest_file= val  }
  opts.on("-C", "--endpoint=val", String)   { |val| endpoint = val }
  opts.on("-y", "--yes")					{ ask_to_advance = false }
  opts.on("-t", "--tunnel=val",String)		{ |val| tunnel_to = val}
  opts.on("-s", "--tunnel-key=val",String) { |val| tunnel_key = val }
  opts.on("-f", "--clean") { clean_only= true }
  opts.on_tail("-h", "--help")         		{ exec "grep ^#/<'#{file}'|cut -c4-" }
  opts.parse!
end

if ARGV.empty?
  puts "ERROR: environment is not specified"
  exec "grep ^#/<'#{file}'|cut -c4-"
  exit 1
end

# Set-up etcd conection
endpoint_uri=URI.parse(endpoint.chomp)
host = endpoint_uri.host
port = endpoint_uri.port
if endpoint_uri.scheme !="http" || host.nil?
	puts "ERROR: Endpoint '#{endpoint}' is not valid. Check format 'http://addr:port'."
	exit 1
end
port= 2379 if port.nil?
endpoint="http://#{host}:#{port}"

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
  tunnel_options[:forward_agent]=true
  unless tunnel_key.nil?
    if !File.exists?(tunnel_key)
      puts "ERROR: Tunnel key #{tunnel_key} do not exists!"
      exit 1
    end
    tunnel_options[:keys]=[tunnel_key]; tunnel_options[:keys_only]=true
    tunnel_options.delete(:password) if tunnel_options.key?(:password) # ignore password if key file used
  end
  print "Creating tunnle to #{tunnel_uri.host} with #{tunnel_uri.user}...."
	$net_gateway = Net::SSH::Gateway.new(tunnel_uri.host,tunnel_uri.user,tunnel_options)
	$gateway_port = $net_gateway.open(host,port)
  puts "OK!"
	#host="127.0.0.1" # chage to local
	#port=$gateway_port
  endpoint="http://127.0.0.1:#{$gateway_port}"
end


# load manifiest
manifest_file="manifest.yml" if manifest_file.nil?
print  "Reading manifest: #{manifest_file}..."
begin
  manifest=YAML.load(File.read(manifest_file))
rescue => e
  puts "ERROR: Could not load manifest #{manifest_file} => #{e}"
  exit 1
end
puts "OK!"

if !manifest.key?(ARGV[0])
  puts "ERROR: Environment #{ARGV[0]} is not present on #{manifest_file}"
  exit 1
end

$manifest=manifest[ARGV[0]] ; $envi=ARGV[0]
fleet_cmd='./fleetctl'
fleet_wd= script_path
ymal_cmd="./etcd-yaml.rb"
ymal_public_key='./.public.gpg'
ymal_private_key='./.secret.gpg'
ymal_prefix=""


# Get commands
ymal_cmd=$manifest['etcd_yaml_cmd'] if $manifest.key?('etcd_yaml_cmd')
ymal_public_key=$manifest['etcd_yaml_public_key'] if $manifest.key?('etcd_yaml_public_key')
ymal_private_key=$manifest['etcd_yaml_private_key'] if $manifest.key?('etcd_yaml_private_key')
ymal_prefix=$manifest['etcd_prefix'] if $manifest.key?('etcd_prefix')
fleet_cmd=$manifest['fleet_cmd'] if $manifest.key?('fleet_cmd')
fleet_wd= File.expand_path $manifest['fleet_workingdir'] if $manifest.key?('fleet_workingdir')
CoreosUnitHelper::set_fleet fleet_cmd,fleet_wd,"-endpoint=\"#{endpoint}\" --driver=\"etcd\""
puts "Using fleet command: #{fleet_cmd} on #{fleet_wd} with endpoint=#{endpoint}"
puts "Using etcd-yaml command: #{ymal_cmd} with keys[#{ymal_public_key}/#{ymal_private_key}] and prefix='#{ymal_prefix}'"

# Check gzip and gpg2
print "External requirements:"
gs=%x(gpg2 --version); print "GPG2 [present:#{$?==0}] #{gs.lines.first}"
gs=%x(gzip --version); puts "GZIP [presnet:#{$?==0}] #{gs.lines.first}"

# Step 0 Load definitios
if !$manifest.key?('unit_definition') || !$manifest['unit_definition'].is_a?(Array) || $manifest['unit_definition'].empty?
  puts "ERROR: unit_definitions malformed in manifest #{manifest_file}"
  exit 1
end
$unit_definitions={}
$manifest['unit_definition'].each do |unit_def|
  unit_def['multi']=false unless unit_def.key?('multi')
  if !unit_def.key?('unit_name') || !unit_def.key?('file')
    puts "ERROR: malformed unit => #{unit_def.inspect}"
    exit 1
  end
  unit_def['base_name']=(unit_def.key?('base_name')) ? unit_def['base_name'] : unit['unit_name']
  print "Loading unit definition #{unit_def['unit_name']}, from #{unit_def['file']} base_name:#{unit_def['base_name']} env:#{$envi}..."
  params=(unit_def.key?('params') && unit_def['params'].is_a?(Hash)) ? unit_def['params'] : {}
  service= CoreosUnitHelper::load_service_from_template unit_def['unit_name'],unit_def['base_name'],unit_def['file'],$envi,params
  if service.nil?
    puts "ERROR: Service unit definition #{unit_def['unit_name']} not valid/not found in #{unit_def['file']}"
    exit 1
  end
  unit_def['suffix']= "service" unless unit_def.key?('suffix')
  unit_def['service'],unit_def['service_sha']= CoreosUnitHelper::dump_service service
  unit_def['unit_file_name']= (unit_def['multi']) ? "#{$envi}-#{unit_def['unit_name']}@" : "#{$envi}-#{unit_def['unit_name']}"
  unit_def['unit_file_name']+=".#{unit_def['suffix']}"
  $unit_definitions[unit_def['unit_name']] = unit_def
  puts "#{unit_def['unit_name']}/#{unit_def['unit_file_name']} Digest:#{unit_def['service_sha'][0..5]}..."
end

# 1 step list machines
puts "Listing current information for #{$envi}...."
puts "-----------------------------------------------------------------------------"
puts "Machines:"
($present_machines=CoreosUnitHelper::machines).each { |m| puts "#{m['METADATA']} => #{m['IP']}" }
puts "Unit files:"
$present_unit_files={}
CoreosUnitHelper::unit_files.each do |uf|
  puts "#{uf['UNIT']}[#{uf['DESC']}] States:#{uf['STATE']}/#{uf['DSTATE']} Global: #{uf['GLOBAL']} Digest:#{uf['SHA'][0..5]}..."
  $present_unit_files[uf['UNIT']]= uf
end

puts "Units:"
($present_units=CoreosUnitHelper::units).each { |u| puts "#{u['UNIT']} States:#{u['ACTIVE']}/#{u['SUB']} machine: #{u['MACHINE']} digest:#{u['SHA'][0..5]}..."}
puts "-----------------------------------------------------------------------------"

if ask_to_advance
  puts "All services will be cleaned and etcd loaded with data before sync. Do you want to continue [y/N]?"
  cont=STDIN.gets.chomp.downcase
  exit 0 if cont!="y"
end

puts "-----------------------------------------------------------------------------"
back_up_file="#{$envi}-#{Time.now.utc.strftime('%Y%m%d%H%M%S')}.yml"
puts "Back-up etcd content for prefix=#{ymal_prefix} in #{back_up_file}... "
puts "-----------------------------------------------------------------------------"
%x(#{ymal_cmd} --file='#{back_up_file}' --endpoint='#{endpoint}' --prefix='#{ymal_prefix}' export)
puts "Result #{$? == 0} file -> #{back_up_file}"
puts "-----------------------------------------------------------------------------"
puts "Clean up units in manifest-Stop & unload & destroying all units in manifest"
puts "-----------------------------------------------------------------------------"
# 2 stop & unload all services in manifest
if !$manifest.key?('units') || !$manifest['units'].is_a?(Array) || $manifest['units'].empty?
  puts "ERROR: Units malformed in #{manifest_file} "
  exit 1
end

$manifest['units'].each do |unit|

  if !unit.key?('unit_name') || !unit.key?('use') || unit['use'].to_i <= 0
    puts "ERROR: malformed unit => #{unit.inspect}"
    exit 1
  end
  if !$unit_definitions.key?(unit['unit_name'])
    puts "ERROR: unit #{unit['unit_name']} has not been defined in unit_definitions"
    exit 1
  end

  multi=$unit_definitions[unit['unit_name']]['multi']
  suffix=$unit_definitions[unit['unit_name']]['suffix']
  if multi

    puts "Stopping & unloading & destroying multi service #{unit['unit_name']}:"

    (1..unit['use']).each do |i|
      nam="#{$envi}-#{unit['unit_name']}@#{i}.#{suffix}"

      if $present_unit_files.key?(nam)
          stopped=($present_unit_files[nam]['DSTATE']=='launched' || $present_unit_files[nam]['STATE']=='launched') ?  CoreosUnitHelper::stop(nam) : "was not launched"
          unloaded=($present_unit_files[nam]['DSTATE']=='loaded' || $present_unit_files[nam]['STATE'] == 'loaded') ? CoreosUnitHelper::unload(nam) : "was not loaded"
        puts "---/[#{nam} -> #{stopped} / #{unloaded} /  #{CoreosUnitHelper::destroy nam}]"
      else
        puts "---/[#{nam} not present -> nothing done!]"
      end

    end

    nam="#{$envi}-#{unit['unit_name']}@.#{suffix}"
    if $present_unit_files.key?(nam)
      puts "---/[#{nam} template -> #{CoreosUnitHelper::destroy nam}]"
    else
      puts "---/[#{nam} not present -> nothing done!]"
    end
  else
    nam="#{$envi}-#{unit['unit_name']}.#{suffix}"

    if $present_unit_files.key?(nam)
      stopped=($present_unit_files[nam]['DSTATE']=='launched' || $present_unit_files[nam]['STATE']=='launched') ?  CoreosUnitHelper::stop( nam) : "was not launched"
      unloaded=($present_unit_files[nam]['DSTATE']=='loaded' || $present_unit_files[nam]['STATE'] == 'loaded') ? CoreosUnitHelper::unload(nam) : "was not loaded"
      puts "Stopping & unloading single service #{nam} -> #{stopped} / #{unloaded} / #{CoreosUnitHelper::destroy nam}"
    else
      puts "#{nam} not present -> nothing done!"
    end

  end

end
exit 0 if clean_only

puts "-----------------------------------------------------------------------------"
puts "Loading etcd config..."
if $manifest.key?('etcd') && $manifest['etcd'].is_a?(Array)
  $manifest['etcd'].each do |conf|
    if conf.is_a?(Hash)
      print "Loading #{conf.keys[0]}..."
      File.write('tmp_conf_etcd.yml',conf.to_yaml)
      result=%x(#{ymal_cmd} --file='tmp_conf_etcd.yml' --endpoint='#{endpoint}' --prefix='#{ymal_prefix}' -k #{ymal_public_key} --yes import)
      puts "#{$? == 0}"
      File.delete 'tmp_conf_etcd.yml' if File.exists?('tmp_conf_etcd.yml')
    end

  end
end
puts "-----------------------------------------------------------------------------"

puts "-----------------------------------------------------------------------------"
# 3 sumit all unit files in manifest
puts "Submiting unit files..."
puts "-----------------------------------------------------------------------------"
$unit_definitions.each_pair do |k,unit_def|
  puts "Submiting #{unit_def['unit_file_name']} -> #{CoreosUnitHelper::submit unit_def['unit_file_name'],unit_def['service'],false}"
end

puts "-----------------------------------------------------------------------------"
# 4 load and start
puts "Loading services from template..."
puts "-----------------------------------------------------------------------------"
$manifest['units'].each do |unit|
  multi=$unit_definitions[unit['unit_name']]['multi']
  suffix=$unit_definitions[unit['unit_name']]['suffix']
  if multi
    print "Loading multi service #{unit['unit_name']}:"
    (1..unit['use']).each do |i|
      puts (nam="#{$envi}-#{unit['unit_name']}@#{i}.#{suffix}")
      print "[#{nam} -> #{CoreosUnitHelper::load nam}]"
    end
    puts "!"
  else
    nam="#{$envi}-#{unit['unit_name']}.#{suffix}"
    puts "Loading single service #{nam} -> #{CoreosUnitHelper::load nam}"
  end
end


puts "-----------------------------------------------------------------------------"
puts "Starting services from template..."
puts "-----------------------------------------------------------------------------"
$manifest['units'].each do |unit|
  multi=$unit_definitions[unit['unit_name']]['multi']
  suffix=$unit_definitions[unit['unit_name']]['suffix']
  if multi
    print "Start multi service #{unit['unit_name']}:"
    (1..unit['use']).each do |i|
      nam="#{$envi}-#{unit['unit_name']}@#{i}.#{suffix}"
      print "[#{nam} -> #{CoreosUnitHelper::start nam}]"
    end
    puts "!"
  else
    nam="#{$envi}-#{unit['unit_name']}.#{suffix}"
    puts "Start single service #{nam} -> #{CoreosUnitHelper::start nam}"
  end
end
puts "-----------------------------------------------------------------------------"
# Close tunnel
if !$gateway.nil? && !$gateway_port.nil?
	$net_gateway.close($gateway_port);
	$net_gateway.shutdown!
end
puts "Sync Finished!"
