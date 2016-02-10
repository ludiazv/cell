# Size of the CoreOS cluster created by Vagrant
$num_instances=3

coreos_cell_dir=File.dirname(File.expand_path('..', __FILE__))
meta_data=["redis=true,nginx=true","db=true","app=true"]
key_files={'/opt/keyring/.secret.gpg' => "#{coreos_cell_dir}/etcd-yaml/secret.gzip.base64",
           '/opt/keyring/.public.gpg' => "#{coreos_cell_dir}/etcd-yaml/public.gzip.base64"}


# Used to fetch a new discovery token for a cluster of size $num_instances
$new_discovery_url="https://discovery.etcd.io/new?size=#{$num_instances}"

# Automatically replace the discovery token on 'vagrant up'

if File.exists?('user-data.yml') && ARGV[0].eql?('up')
  require 'open-uri'
  require 'yaml'

  token = open($new_discovery_url).read

  data = YAML.load(IO.readlines('user-data.yml')[1..-1].join)

  if data.key? 'coreos' and data['coreos'].key? 'etcd'
    data['coreos']['etcd']['discovery'] = token
  end

  if data.key? 'coreos' and data['coreos'].key? 'etcd2'
    data['coreos']['etcd2']['discovery'] = token
  end

  # Fix for YAML.load() converting reboot-strategy from 'off' to `false`
  if data.key? 'coreos' and data['coreos'].key? 'update' and data['coreos']['update'].key? 'reboot-strategy'
    if data['coreos']['update']['reboot-strategy'] == false
      data['coreos']['update']['reboot-strategy'] = 'off'
    end
  end

  (1..$num_instances).each do |i|
    # add metadata
    if data.key? 'coreos' and data['coreos'].key? 'fleet' and data['coreos']['fleet'].is_a?(Hash)
      data['coreos']['fleet']['metadata']= "#{meta_data[i-1]}"
    end
    
    key_files.each_pair do |file,src|
      data['write_files']=[] unless data.key? 'write_files'
      content=IO.read(src)
      data['write_files'] << {   'path'=> file,
                                  'owner'=> "root:root",
                                  'permissions'=> "0400",
                                  'encoding'=> "gzip+base64",
                                  'content'=> content }

    end
    yaml = YAML.dump(data)
    File.open("user-data-#{i}", 'w') { |file| file.write("#cloud-config\n\n#{yaml}") }
  end
end

#
# coreos-vagrant is configured through a series of configuration
# options (global ruby variables) which are detailed below. To modify
# these options, first copy this file to "config.rb". Then simply
# uncomment the necessary lines, leaving the $, and replace everything
# after the equals sign..

# Change basename of the VM
# The default value is "core", which results in VMs named starting with
# "core-01" through to "core-${num_instances}".
$instance_name_prefix="cell"

# Change the version of CoreOS to be installed
# To deploy a specific version, simply set $image_version accordingly.
# For example, to deploy version 709.0.0, set $image_version="709.0.0".
# The default value is "current", which points to the current version
# of the selected channel
#$image_version = "current"

# Official CoreOS channel from which updates should be downloaded
$update_channel='stable'

# Log the serial consoles of CoreOS VMs to log/
# Enable by setting value to true, disable with false
# WARNING: Serial logging is known to result in extremely high CPU usage with
# VirtualBox, so should only be used in debugging situations
#$enable_serial_logging=false

# Enable port forwarding of Docker TCP socket
# Set to the TCP port you want exposed on the *host* machine, default is 2375
# If 2375 is used, Vagrant will auto-increment (e.g. in the case of $num_instances > 1)
# You can then use the docker tool locally by setting the following env var:
#   export DOCKER_HOST='tcp://127.0.0.1:2375'
#$expose_docker_tcp=2375

# Enable NFS sharing of your home directory ($HOME) to CoreOS
# It will be mounted at the same path in the VM as on the host.
# Example: /Users/foobar -> /Users/foobar
#$share_home=false

# Customize VMs
#$vm_gui = false
$vm_memory = 512
$vm_cpus = 1

# Share additional folders to the CoreOS VMs
# For example,
# $shared_folders = {'/path/on/host' => '/path/on/guest', '/home/foo/app' => '/app'}
# or, to map host folders to guest folders of the same name,
# $shared_folders = Hash[*['/home/foo/app1', '/home/foo/app2'].map{|d| [d, d]}.flatten]

$shared_folders = { coreos_cell_dir => '/home/core/coreos_cell' }

# Enable port forwarding from guest(s) to host machine, syntax is: { 80 => 8080 }, auto correction is enabled by default.
#$forwarded_ports = {}
