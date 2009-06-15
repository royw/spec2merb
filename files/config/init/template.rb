module Merb::Template
  class << self
    # overwrite the load_template_io to look in app/views/templates if the
    # given path is not found
    def load_template_io(path)
      io = super
      Merb.logger.debug "Merb's load_template_io(#{path}) => #{io.inspect}"
      if io.nil?
        if path =~ %r((.*/app/views/).*(/[^/]+)$)
          template_path = $1 + 'templates' + $2
          file = Dir["#{template_path}.{#{template_extensions.join(',')}}"].first
          io = File.open(file, "r") if file
          Merb.logger.debug "App's load_template_io(#{template_path}) => #{io.inspect}"
        end
      end
      io
    end
  end
end
