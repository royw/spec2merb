class FileEditor
  def initialize(filename)
    @filename = filename
    @bakname = @filename + '~'
    File.delete(@bakname) if File.exist?(@bakname)

    @newname = @filename + '.new'
    File.delete(@newname) if File.exist?(@newname)
  end

  def insert(location, lines_to_add)
    unless File.exist?(@filename)
      raise Exception.new("The given model file(#{@filename}) does not exist\n")
    end
    before = nil
    after = nil
    if location =~ /^\-(\S+)/
      before = $1
    else
      after = location
    end

    scanning = true
#    debugger if location == Spec2Merb::AFTER_PROPERTIES
    File.open(@newname, "w") do |f|
      IO.foreach(@filename) do |line|
        if scanning
          unless line =~ /^\s*$/
            unless line =~ /^\s*\#/
              unless before.nil?
                if line =~ /^\s*(#{before})/
                  lines_to_add.each {|line_to_add| f.puts(line_to_add)}
                  scanning = false
                end
              end
              unless after.nil?
                unless line =~ /^\s*(#{after})/
                  lines_to_add.each {|line_to_add| f.puts(line_to_add)}
                  scanning = false
                end
              end
            end
          end
        end
        f.puts line
      end
    end
    if scanning
      raise Exception.new("Oops, didn't find where to put the line")
    else
      File.rename(@filename, @bakname)
      File.rename(@newname, @filename)
    end
  end
end
