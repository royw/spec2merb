class SaveException < Exception
  def initialize(obj, msg=nil)
    unless obj.errors.empty?
      buf = []
      buf << msg unless msg.nil?
      buf << obj.inspect
      buf += obj.errors.collect{|e| '  ' + e.inspect}
      super(buf.join("\n"))
    end
  end
end
