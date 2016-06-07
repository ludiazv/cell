require 'yaml'
require 'erubis'
require 'digest'

module CoreosUnitHelper

  def self.set_fleet(cmd,working_dir,opt)
    @@fleet_cmd=cmd
    @@fleet_wd=working_dir
    @@fleet_op=opt
    @@ssh=nil
  end

  def self.set_ssh(ssh)
    @@ssh=ssh
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
    exit_code=1; result=""
    if @@ssh.nil? # execlute local
      Dir.chdir @@fleet_wd
      result=%x(#{@@fleet_cmd} #{@@fleet_op} #{cmd})
      exit_code=$?.to_i
    else  # execute via SSH
      exit_code,result= @@ssh.execro! "MYPWD=$(pwd) ; cd #{@@fleet_wd} && #{@@fleet_cmd} #{@@fleet_op} #{cmd} ; cd $MYPWD"
    end
    puts result if verbose
    return exit_code,result
  ensure
    Dir.chdir pwd
  end

  def self.macro_interpolation(o)
    if o.is_a?(Array)
      o.each_with_index do |v,i|
        o[i]= eval('"' + v + '"') if v.is_a?(String)
        macro_interpolation o[i] if v.is_a?(Hash) || v.is_a?(Array)
      end
    end
    if o.is_a?(Hash)
      o.each_pair do |k,v|
        o[k]= eval('"' + v + '"') if v.is_a?(String)
        macro_interpolation o[k] if v.is_a?(Hash) || v.is_a?(Array)
      end
    end

  end

  def self.load_unit_definitions(root,envi,verbose=false,tag="unit_definition")
    if !root.is_a?(Hash) && !root.key?(tag) || !root[tag].is_a?(Array) ||
       root[tag].empty?
       msg= "ERROR: unit_definitions malformed in manifest"
       puts msg if verbose
       return msg,false
    end
    unit_definitions={}
    root[tag].each do |unit_def|
      unit_def['multi']=false unless unit_def.key?('multi')
      if !unit_def.key?('unit_name') || !unit_def.key?('file')
        msg= "ERROR: malformed unit => #{unit_def.inspect}"
        puts msg if verbose
        return msg,false
      end

      unit_def['base_name']=(unit_def.key?('base_name')) ? unit_def['base_name'] : unit['unit_name']
      unit_def['params']=(unit_def.key?('params') && unit_def['params'].is_a?(Hash)) ? unit_def['params'] : {}
      macro_interpolation unit_def
      print "Loading unit definition #{unit_def['unit_name']}, from #{unit_def['file']} base_name:#{unit_def['base_name']} env:#{envi}->" if verbose
      service= load_service_from_template unit_def['unit_name'],unit_def['base_name'],unit_def['file'],envi,unit_def['params']
      if service.nil?
        msg= "ERROR: Service unit definition #{unit_def['unit_name']} not valid/not found in #{unit_def['file']}"
        puts msg if verbose
        return msg, false
      end
      unit_def['suffix']= "service" unless unit_def.key?('suffix')
      unit_def['service'],unit_def['service_sha']= dump_service service
      unit_def['unit_file_name']= (unit_def['multi']) ? "#{envi}-#{unit_def['unit_name']}@" : "#{envi}-#{unit_def['unit_name']}"
      unit_def['unit_file_name']+=".#{unit_def['suffix']}"
      unit_definitions[unit_def['unit_name']] = unit_def
      puts "#{unit_def['unit_name']}/#{unit_def['unit_file_name']} Digest:#{unit_def['service_sha'][0..5]}..." if verbose
    end
    return unit_definitions,true
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

  def self.unit_files(no_cat=false)
    unit_fil=list_cmd "list-unit-files --full --fields=desc,dstate,global,hash,state,target,unit"
    unit_fil.each do |uf|
      uf['CONTENT'],uf['SHA']= nil, nil
      uf['CONTENT'],uf['SHA']= cat(uf['UNIT']) if uf.key?('UNIT') && !no_cat
    end
    unit_fil
  end

  def self.units(no_cat=false)
    units= list_cmd "list-units --full --fields=unit,machine,active,sub"
    units.each do |unit|
      unit['CONTENT'],unit['SHA']= nil, nil
      unit['CONTENT'],unit['SHA']= cat(unit['UNIT']) if unit.key?('UNIT') && !no_cat
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

  def self.submit_simple(unit_name_file)
    code,result=exe_fleet "submit #{unit_name_file}"
    code == 0
  end

  def self.stop(unit)
    code,result=exe_fleet "stop #{unit}"
    code == 0
  end

  def self.unload(unit,n=0)
    code,result= 0,nil
    if n==-1
      code,result=exe_fleet "unload --no-block #{unit}"
    else
      code,result=exe_fleet "unload --block-attempts=#{n} #{unit}"
    end
    code == 0
  end
  def self.destroy(unit)
    code, result = exe_fleet "destroy #{unit}"
    code == 0
  end
  def self.load(unit,n=0)
    code,result= 0,nil
    if n==-1
      code,result=exe_fleet "load --no-block #{unit}"
    else
      code,result=exe_fleet "load --block-attempts=#{n} #{unit}"
    end
    code == 0
  end

  def self.start(unit,n=0)
    code,result= 0,nil
    if n==-1
      code,result=exe_fleet "start --no-block #{unit}"
    else
      code,result=exe_fleet "start --block-attempts=#{n} #{unit}"
    end
    code == 0
  end

  def self.cat(unit)
    code,result=exe_fleet "cat #{unit}"
    return nil,nil if code != 0
    return result, Digest::SHA256.hexdigest(result)
  end

end
