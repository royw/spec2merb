class ModelEditor < FileEditor
  APP_MODELS_DIR = 'app/models'
  
  def initialize(model_name)
    @model_name = model_name
    if model_name =~ /\//
      filename = model_name
    else
      filename = File.join(APP_MODELS_DIR, model_name)
    end
    filename += '.rb' unless filename =~ /\.rb$/
    super(filename)
  end
  
  def fixup_properties
    begin
      File.open(@newname, 'w') do |file|
        IO.foreach(@filename) do |line|
          if line =~ /^\s*property\s+(\:\S+),\s+(\S+)\s*$/
            name = $1
            sqltype = $2
            file.puts(line.gsub(sqltype, to_dmtype(sqltype)))
          else
            file.puts(line)
          end
        end
      end
      File.rename(@filename, @bakname)
      File.rename(@newname, @filename)
    rescue Exception => e
      puts e.to_s
    end
  end  
  
  def generate_resource(properties)
    line = "merb-gen resource #{@model_name.snake_case}"
    unless properties.nil?
      line += " '#{properties.join(',')}'"
    end
    puts `#{line}`
  end
  
  protected

  def option(dm_type, modifier, value)
    existing_regex = /#{modifier}\s*=>\s*\S+/
    if dm_type =~ existing_regex
      dm_type.gsub(existing_regex, "#{modifier} => #{value}")
    else
      dm_type += ", :#{modifier} => #{value}"
    end
    dm_type
  end

  def to_dmtype(sqltype)
    dm_type = sqltype
    dm_type = "Boolean" if sqltype =~ /BOOLEAN/i
    dm_type = "Float" if sqltype =~ /FLOAT/i
    dm_type = "Double" if sqltype =~ /DOUBLE/i
    dm_type = "BigDecimal" if sqltype =~ /REAL/i
    dm_type = "BigDecimal" if sqltype =~ /NUMERIC/i
    dm_type = "BigDecimal" if sqltype =~ /DECIMAL/i
    dm_type = "Date" if sqltype =~ /DATE/i
    dm_type = "Time" if sqltype =~ /TIME/i
    dm_type = "Timestamp" if sqltype =~ /TIMESTAMP/i
    dm_type = "DateTime" if sqltype =~ /DATETIME/i
    dm_type = "String, :length => #{$1}" if sqltype =~ /CHAR\((\d+)\)/i
    dm_type = "String, :length => #{$1}" if sqltype =~ /CHARACTER\((\d+)\)/i
    dm_type = "Text, :length => #{$1}" if sqltype =~ /VARCHAR\((\d+)\)/i
    dm_type = "Text, :length => #{$1}" if sqltype =~ /NVARCHAR\((\d+)\)/i
    dm_type = "Text" if sqltype =~ /TEXT/i
    dm_type = "Text, :length => #{$1}" if sqltype =~ /TEXT\((\d+)\)/i
    dm_type = "Text, :length => #{$1}" if sqltype =~ /STRING\((\d+)\)/i
    dm_type = "Integer, :minimum => -2147483648, :maximum => 2147483647" if sqltype =~ /INT/i
    dm_type = "Integer, :minimum => -2147483648, :maximum => 2147483647" if sqltype =~ /INTEGER/i
    dm_type = "Integer, :minimum => -9223372036854775808, :maximum => 9223372036854775807" if sqltype =~ /BIGINT/i
    dm_type = "Integer, :minimum => -32768, :maximum => 32767" if sqltype =~ /SMALLINT/i
    dm_type = "Integer, :minimum => -128, :maximum => 127" if sqltype =~ /TINYINT/i

    # modifiers
    dm_type = option(dm_type, "index", $1)      if sqltype =~ /INDEX=(\S+)/i
    dm_type = option(dm_type, "key", $1)        if sqltype =~ /KEY=(\S+)/i
    dm_type = option(dm_type, "length", $1)     if sqltype =~ /LENGTH=(\S+)/i
    dm_type = option(dm_type, "minimum", $1)    if sqltype =~ /MIN=(\S+)/i
    dm_type = option(dm_type, "maximum", $1)    if sqltype =~ /MAX=(\S+)/i
    dm_type = option(dm_type, "nullable", $1)   if sqltype =~ /NULL=(\S+)/i
    dm_type = option(dm_type, "format", $1)     if sqltype =~ /FORMAT=(\S+)/i
    dm_type = option(dm_type, "unique", 'true') if sqltype =~ /UNIQUE/i
    dm_type = option(dm_type, "default", $1)    if sqltype =~ /DEFAULT=(\S+)/i

    dm_type
  end
end

