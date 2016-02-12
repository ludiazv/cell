require 'yaml'
require 'erubis'
require 'digest'

module CoreosUnitHelper

  def self.set_fleet(cmd,working_dir,opt)
    @@fleet_cmd=cmd
    @@fleet_wd=working_dir
    @@fleet_op=opt
  end
  
  # strip bash \CR multiline commands
  def self.normalize_service_attribute(s)
    if s.is_a?(String)
      s.strip.gsub(/\\\s*\n/,'')
    else
      s
    end
    
  end
  def self.dump_service(h)
    s=""
    h.each_pair do |section,options|
      s << "\n[#{section}]\n"
      if options.is_a?(Hash)
        options.each_pair do |k,op|
          if op.is_a?(Array)
            op.each { |e| s << "#{k}=#{normalize_service_attribute e}\n"}
          else
            s << "#{k}=#{normalize_service_attribute op}\n"
          end
        end
      end
    end
    s=s[1..-1] if s.length > 0  # remove frist \n to match with fleetd processed units
    return s, Digest::SHA256.hexdigest(s)
  end
  
  def self.exe_fleet(cmd,verbose=false)
    pwd=Dir.pwd
    Dir.chdir @@fleet_wd
    result=%x(#{@@fleet_cmd} #{@@fleet_op} #{cmd})
    puts result if verbose
    return $?.to_i, result
  ensure
    Dir.chdir pwd
  end

  def self.load_service_from_template(unit_name,base_name,file,env,paramst={})
    template=Erubis::Eruby.new(File.read(file))
    yml_raw=template.result({unit_name: unit_name, base_name: base_name, environment: env, params:paramst})
    services_infile=YAML.load(yml_raw)
    (services_infile.is_a?(Hash) && services_infile.key?(unit_name)) ? services_infile[unit_name] : nil
  rescue =>e
    puts e
    nil
  end

  def self.list_cmd(cmd)
    code,result=exe_fleet cmd
    elements=[];names=[]
    if code == 0
       lines=result.split(/\n+/)
       if lines.length > 1
         names=lines.first.split(/\t\s*/)
         names.map(&:upcase)
         lines.delete_at 0
         lines.each do |l|
           row=l.split(/\t\s*/)
           if row.length == names.length
             element={}
             names.each_with_index { |n,i| element[n]=row[i]}
             elements << element
           end
         end
       end
     end
     elements
  end
  
  def self.machines
    list_cmd "list-machines --full"
  end
  
  def self.unit_files
    unit_fil=list_cmd "list-unit-files --full --fields=desc,dstate,global,hash,state,target,unit"
    unit_fil.each do |uf|
      uf['CONTENT'],uf['SHA']= cat(uf['UNIT']) if uf.key?('UNIT')
    end
    unit_fil
  end
  
  def self.units
    units= list_cmd "list-units --full --fields=unit,machine,active,sub"
    units.each do |unit|
      unit['CONTENT'],unit['SHA']= cat(unit['UNIT']) if unit.key?('UNIT')
    end
    units
  end
  
  def self.submit(unit_name_file,cont,delete_tmp=true)
    File.write(unit_name_file, cont)
    full_path=File.expand_path unit_name_file
    code,result=exe_fleet "submit #{full_path}"
    code == 0
  ensure
    File.delete unit_name_file if File.exists?(unit_name_file) && delete_tmp
  end
  
  def self.stop(unit)
    code,result=exe_fleet "stop #{unit}"
    code == 0
  end
  
  def self.unload(unit,n=0)
    code,result=exe_fleet "unload --block-attempts=#{n} #{unit}"
    code == 0
  end
  def self.destroy(unit)
    code, result = exe_fleet "destroy #{unit}"
    code == 0
  end
  def self.load(unit,n=0)
    code,result=exe_fleet "load --block-attempts=#{n} #{unit}"
    code == 0
  end
  
  def self.start(unit,n=0)
    code,result=exe_fleet "start --block-attempts=#{n} #{unit}"
    code == 0
  end
  
  def self.cat(unit)
    code,result=exe_fleet "cat #{unit}"
    return nil,nil if code != 0
    return result, Digest::SHA256.hexdigest(result)
  end
  
end
