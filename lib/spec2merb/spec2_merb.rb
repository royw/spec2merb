class Spec2Merb

  BEFORE_CLASS = '-class'
  AFTER_PROPERTIES = 'class|include|is_paginated|property'
  AFTER_RELATIONSHIPS = 'class|include|is_paginated|property|belongs_to|has|is'
  AFTER_INCLUDES = 'class|include'
  AFTER_REQUIREMENTS = 'class|include|is_paginated|property|belongs_to|has|is'

  def initialize(name)
    @project_name = name
    @descriptions = []
    @relationships = []
    @properties = {}
    @requirements = {}
    @routes = {}
    @synopses = {}
  end
  
  def dump
    {
      :project_name => @project_name, 
      :descriptions => @descriptions, 
      :relationships => @relationships, 
      :properties => @properties, 
      :requirements => @requirements, 
      :routes => @routes, 
      :synopsis => @synopsis
    }.to_yaml
  end

  # capture the describe info from the rspec
  def describe(str,&blk)
    unless str.nil?
      if str =~ /^\s*(\S+)\s+Model\s*$/
        @descriptions << $1
        @routes[$1] ||= []
      end
    end
    blk.call unless blk.nil?
  end

  # capture the it info from the rspec
  def it(str,&blk)
    description = @descriptions.last
    through_singular = nil
    through_plural = nil
    if str =~ /\[.*\svia\s(\S+)\s*\]/
      through_singular = $1.snake_case
      through_plural = through_singular.pluralize
    end
    if str =~ /^should have a relationship.*\s(\S+)\s+\((.*)\)\s*\[has\s+(\S+)\s+(\S+)[^\]]*\]/
      @relationships << {
        :filename => description,
        :variable => $1,
        :comment => $2,
        :has_relationship => $3,
        :model => $4,
        :through => through_plural
      }
      @routes[description] << $1
    elsif str =~ /should have a relationship.*\s(\S+)\s*\[has\s+(\S+)\s+(\S+)[^\]]*\]/
      @relationships << {
        :filename => description,
        :variable => $1,
        :comment => '',
        :has_relationship => $2,
        :model => $3,
        :through => through_plural
      }
      @routes[description] << $1
    elsif str =~ /^should declare a list.*\s(\S+)\s+\((.*)\)\s*\[list[^\]]*\]/
      @relationships << {
        :filename => description,
        :variable => $1,
        :comment => $2,
        :relationship => "is :list, :scope => [:#{$1}_id]",
        :through => through_plural
      }
    elsif str =~ /^should declare a list.*\s(\S+)\s*\[list[^\]]*\]/
      @relationships << {
        :filename => description,
        :variable => $1,
        :comment => '',
        :relationship => "is :list, :scope => [:#{$1}_id]",
        :through => through_plural
      }
    elsif str =~ /^should reference.*\s(\S+)\s+\((.*)\)\s*\[belongs_to\s+(\S+)[^\]]*\]/
      @relationships << {
        :filename => description,
        :variable => $1,
        :comment => $2,
        :relationship => "belongs_to :#{$1}",
        :model => $3
      }
      @routes[description] << $1
    elsif str =~ /^should reference.*\s(\S+)\s*\[belongs_to\s+(\S+)[^\]]*\]/
      @relationships << {
        :filename => description,
        :variable => $1,
        :comment => '',
        :relationship => "belongs_to :#{$1}",
        :model => $2
      }
      @routes[description] << $1
    elsif str =~ /should have.*\s(\S+)\s*\(.*?\)\s*\[(\S+)[^\]]*\]/
      @properties[description] ||= []
      @properties[description] << "#{$1}:#{$2}"
    elsif str =~ /should have.*\s(\S+)\s*\[(\S+)[^\]]*\]/
      @properties[description] ||= []
      @properties[description] << "#{$1}:#{$2}"
    else
      @requirements[description] ||= []
      @requirements[description] << str
    end
  end

  # capture the synopsis info from the rspec
  def synopsis(*args)
    description = @descriptions.last
    @synopses[description] = args
  end

  def generate(spec)
    rm_rf @project_name
    `merb-gen app #{@project_name}`
    cd(@project_name) do
      eval spec
      gen_descriptions
      gen_relationships
      gen_requirements
      gen_add_methods
      gen_router
      gen_request_specs
      
      # replace generated controllers with what we need when using restful routes
      # as defined in the app/controllers/application.rb
      hack_controllers

      # add/overwrite some files
      mkdir('config/init')
      mkdir_p('lib/tasks')
      cp_r(Dir.glob('../files/*'), '.')
      # gem changed the api in version 1.3.2, I think, at least it is changed
      # in version 1.3.4, so the following merb hack is necessary for merb
      # 1.0.11
      # TODO: this should be generically performed outside of the spec2merb script
      if Versionomy.parse(`gem --version`) < Versionomy.parse('1.3.4')
        raise Exception.new 'Please upgrade rubygems to at least 1.3.4 (sudo gem update --system)'
      end
      if File.exist?('tasks/merb.thor/gem_ext_4.rb')
        rm('tasks/merb.thor/gem_ext.rb') if File.exist?('tasks/merb.thor/gem_ext.rb')
        mv('tasks/merb.thor/gem_ext_4.rb', 'tasks/merb.thor/gem_ext.rb')
      end
    end
    
    def install
      cd(@project_name) do
        puts `rake db:automigrate`
        puts `rake action="all" dev:gen:view`
        puts `thor merb:gem:install`
        puts 'rake doc:diagrams'
      end
    end
  end
  
  def hack_controllers
    files = Dir.glob("app/controllers/*.rb")
    files.each do |filename|
      controllername = File.basename(filename, '.*').camel_case
      next if ['Application', 'Exceptions'].include?(controllername)
      File.delete(filename)
      File.open(filename, 'w') do |file|
        file.puts <<END_CONTROLLER
# The REST methods are in the Application controller.
# You will probably want to def the sort_options here.
class #{controllername} < Application
# provides :xml, :yaml, :js
  provides :xml
  
# def sort_options
#    {:order => [:name.asc]}
# end

end
END_CONTROLLER
      end
    end
  end

  def gen_descriptions
    @descriptions.each do |name|
      editor = ModelEditor.new(name.snake_case)
      editor.generate_resource(@properties[name])
      editor.fixup_properties
      editor.insert(BEFORE_CLASS, model_comments(name))
      editor.insert(AFTER_INCLUDES, '  include AssociationHelper')
      editor.insert(AFTER_INCLUDES, '  is_paginated')
      editor.insert(AFTER_REQUIREMENTS, def_to_s(@properties[name]))
    end
  end
  
  def gen_relationships
    @relationships.each do |rel|
      through_str = ''
      lines = []
      if rel[:has_relationship]
        has_relationship = rel[:has_relationship].gsub(':', '..')
        case has_relationship
        when '1'
          rel_str = 'belongs_to'
        when 'n'
          rel_str = "has n,"
        else
          rel_str = "has #{has_relationship},"
          if rel[:through]
            through_str = ", :through => :#{rel[:through]}"
          else
            through_str = ", :through => Resource"
          end
        end
      
        if rel[:through]
          lines << "  has n, :#{rel[:through]}"
        end
        line = "  #{rel_str} :#{rel[:variable]}#{through_str}"
        line += "     # #{rel[:comment]}" unless rel[:comment].empty?
        lines << line
      elsif rel[:relationship]
        lines << '  ' + rel[:relationship]
      end
      editor = ModelEditor.new(rel[:filename].snake_case)
      editor.insert(AFTER_PROPERTIES, lines)
    end
  end

  def gen_requirements
    @requirements.each do |name, value|
      editor = ModelEditor.new(name.snake_case)
      editor.insert(AFTER_RELATIONSHIPS, "  # #{value}")
    end
  end
  
  def gen_add_methods
    Dir.glob("../methods/**/*.rb").each do |filespec|
      str = IO.read(filespec)
      filename = $1 if filespec =~ /\/methods\/(.*)/
      if File.exist?(filename)
        editor = ModelEditor.new(filename)
        editor.insert(AFTER_RELATIONSHIPS, str)
      else
        Merb.logger.warn {"Can not add methods from '#{filespec}' to '#{filename}' because the file does not exist."}
      end
    end
  end

  def gen_router
    filename = 'config/router.rb'
    bakname = 'config/router.rb~'
    File.delete(bakname) if File.exist?(bakname)
    File.rename(filename, bakname)
    File.open(filename, "w") do |file|
      file.puts(router_content)
    end
  end
  
  def gen_request_specs
    Dir.glob('spec/requests/*.rb').each do |filename|
      editor = RequestSpecEditor.new(filename)
      editor.add_directions
    end
  end

  # geneate model comment from synopsis
  def model_comments(name)
    buf = []
    unless @synopses[name].nil?
      @synopses[name].each do |line|
        buf << "# #{line.gsub("'", '\'').gsub('"', '\"')}"
      end
    end
    buf
  end

  # generate the to_s method to add to a model class
  def def_to_s(properties)
    buf = []
    unless properties.nil?
      buf << '  def to_s'
      buf << "    buf = []"
      properties.each do |prop|
        name = prop
        name = $1 if prop =~ /^(.*)\:/
        buf << "    buf << \":" + name.to_s + " => \" + send(\"" + name.to_s + "\").inspect"
      end
      buf << "    buf.join(\",\")"
      buf << '  end'
      buf << ''
    end
    buf
  end
  

  ROUTER_HEADER = <<END_ROUTER_HEADER
# Merb::Router is the request routing mapper for the merb framework.
#
# You can route a specific URL to a controller / action pair:
#
#   match("/contact").
#     to(:controller => "info", :action => "contact")
#
# You can define placeholder parts of the url with the :symbol notation. These
# placeholders will be available in the params hash of your controllers. For example:
#
#   match("/books/:book_id/:action").
#     to(:controller => "books")
#
# Or, use placeholders in the "to" results for more complicated routing, e.g.:
#
#   match("/admin/:module/:controller/:action/:id").
#     to(:controller => ":module/:controller")
#
# You can specify conditions on the placeholder by passing a hash as the second
# argument of "match"
#
#   match("/registration/:course_name", :course_name => /^[a-z]{3,5}-\d{5}$/).
#     to(:controller => "registration")
#
# You can also use regular expressions, deferred routes, and many other options.
# See merb/specs/merb/router.rb for a fairly complete usage sample.

Merb.logger.info("Compiling routes...")
Merb::Router.prepare do
  # RESTful routes
END_ROUTER_HEADER

  ROUTER_FOOTER = <<END_ROUTER_FOOTER

  # Adds the required routes for merb-auth using the password slice
  slice(:merb_auth_slice_password, :name_prefix => nil, :path_prefix => "")

  # This is the default route for /:controller/:action/:id
  # This is fine for most cases.  If you are heavily using resource-based
  # routes, you may want to comment/remove this line to prevent
  # clients from calling your create or destroy actions with a GET
  # default_routes

  # Change this for your home page to be available at /
  # match("/").to(:controller => "whatever", :action =>"index")
  match("/").to(:controller => "media_objects", :action =>"index")
end
END_ROUTER_FOOTER

  DEPTH_LIMIT = 2

  # generate the replacement content for the config/router.rb file.
  def router_content
    buf = []
    buf << ROUTER_HEADER
    indent = 1
    new_routes = routes_fix_names(@routes)
    @descriptions.sort.each do |name|
      buf += find_route(indent, name, new_routes, DEPTH_LIMIT)
    end
    buf << ROUTER_FOOTER
    buf.join("\n")
  end
  
  # @routes => {'Name' => [names,...]}
  
  def routes_fix_names(old_routes)
    new_routes = {}
    old_routes.each do |key,values|
      # puts "old_routes[#{key}] => #{values.inspect}"
      new_routes[key] = values.collect do |subname|
        searchname = nil
        if old_routes[subname]
          searchname = subname 
        elsif old_routes[subname.camel_case]
          searchname = subname.camel_case
        elsif old_routes[subname.singularize.camel_case]
          searchname = subname.singularize.camel_case
        end
        searchname
      end.compact.uniq
      # puts "new_routes[#{key}] => #{new_routes[key].inspect}"
    end
    new_routes
  end
  
  # @routes => {'Name' => [{'Name' => [{'Name' => [...]}]}]}
  

  def find_route(indent, name, routes, depth_limit, footprints=[])
    buf = []
    unless footprints.include?(name)
      footprints << name
      # debugger if name == 'Delta'
      if routes[name].blank?
        buf << (' ' * (2 * indent)) + "resources :#{name.snake_case.singularize.pluralize}"
      else
        value_buf = []
        unless indent >= depth_limit
          routes[name].each do |subname|
            value_buf += find_route(indent + 1, subname, routes, depth_limit, footprints)
          end
        end
        if value_buf.empty?
          buf << (' ' * (2 * indent)) + "resources :#{name.snake_case.singularize.pluralize}"
        else
          buf << (' ' * (2 * indent)) + "resources :#{name.snake_case.singularize.pluralize} do"
          buf += value_buf
          buf << (' ' * (2 * indent)) + "end"
        end
      end
      footprints.delete(name)
    end
    buf
  end
      
end

