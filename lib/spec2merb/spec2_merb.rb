
class Spec2Merb
  attr_accessor :route_depth

  BEFORE_CLASS = '-class'
  AFTER_PROPERTIES = 'class|include|is_paginated|property'
  AFTER_RELATIONSHIPS = 'class|include|is_paginated|property|belongs_to|has|is'
  AFTER_INCLUDES = 'class|include'
  AFTER_REQUIREMENTS = 'class|include|is_paginated|property|belongs_to|has|is'

  def initialize(name, specfilename)
    @project_name = name
    @spec_filename = specfilename
    @route_depth = 2
    @parser = SpecParser.new
  end
  
  # generate the project from the given spec string
  def generate(spec)
    setup_project(@project_name)
    add_default_files_to_definition
    `merb-gen app --force #{@project_name}`
    cd(@project_name) do
      @parser.parse(spec)
      gen_descriptions
      gen_relationships
      gen_requirements
      # gen_add_methods
      gen_router
      gen_request_specs
      
      # replace generated controllers with what we need when using restful routes
      # as defined in the app/controllers/application.rb
      hack_controllers

      add_files_to_project
      add_spec_to_project
      gen_app_config_file
      gen_jeweler_rake
    end
  end
  
  # setup the project
  def setup_project(name)
    unless File.exist?(name)
      mkdir name
    end
    cd(name) do
      unless File.exist?('.git')
        puts "Initializing git in #{name}"
        `echo '*~' > .gitignore`
        git_initialize
      end
      git_checkout_generated_branch
      puts `git branch`
      puts 'deleting'
      # `git checkout generated`
      Dir.glob('**/*').each do |filename| 
        # next if filename == 'README'
        if File.file?(filename)
          puts "deleting: #{filename}"
          File.delete(filename)
        end
      end
      Dir.glob('*').each do |filename| 
        puts "deleting: #{filename}"
        if File.directory?(filename)
          rm_rf(filename)
        end
      end
    end
  end
  
  # initialize the git repository in the generated project directory
  def git_initialize
    g = Git.init
    g.add('.')
    g.commit('project created')
  end
  
  # use the generated branch
  def git_checkout_generated_branch
    g = Git.open('.')
    g.branch('generated').checkout
  end
  
  # install the time consuming stuff done after generated
  def install
    cd(@project_name) do
      puts `rake db:automigrate`
      puts `rake action="all" dev:gen:view`
      puts `thor merb:gem:install`
      puts `bin/rake doc:diagrams`
    end
  end
  
  # commit and merge the generated project
  def commit_and_merge
    Dir.glob("**/*~").each do |filename|
      if File.file?(filename)
        File.delete(filename)
      end
    end
    cd(@project_name) do
      now = Time.now.to_s
      g = Git.open('.')
      g.add('.')
      g.commit("generated #{now}")
      g.branch('master').checkout

      # it's safer to have the user do the rebase so tell them how
      puts 'If the files on the "generated" branch are ok, then run:'
      puts
      puts '  git rebase generated master'
      puts
      puts 'to update your master branch with the new generated files.'
      puts 'Note, if there are merge problems, resolve them then run:'
      puts
      puts '  git rebase --continue'
      puts
    end
  end

  # copy files from the Spec2Merb/files/ to the current directory's files/
  # Does not overwrite
  def add_default_files_to_definition
    mkdir_p('files')
    default_files = File.join(File.dirname(__FILE__), '../../files')
    files = []
    chdir(default_files) do
      files += Dir.glob("**/*")
    end
    files.each do |filespec|
      dest = File.join('files', filespec)
      unless File.exist?(dest)
        src = File.join(default_files, filespec)
        if File.file?(src)
          destdir = File.dirname(dest)
          mkdir_p(destdir) unless File.exist?(destdir)
          # puts "cp(#{src}, #{dest}), destdir => #{destdir}"
          cp(src, dest)
        end
      end
    end
  end

  # copy (overwrite) the files in the files/ directory to the generated project
  def add_files_to_project
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
  
  # add a copy of the spec used to create the project to
  # the project's doc directory
  def add_spec_to_project
    mkdir_p('doc')
    cp("../#{@spec_filename}", 'doc')
  end
  
  # The REST controllers are much simpler than the default generated
  # controllers so replace them
  def hack_controllers
    files = Dir.glob("app/controllers/*.rb")
    files.each do |filename|
      controllername = File.basename(filename, '.*').camel_case
      next if ['Application', 'Exceptions', 'RestController'].include?(controllername)
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

  # add some extras to each model file
  def gen_descriptions
    @parser.descriptions.each do |name|
      editor = ModelEditor.new(name.snake_case)
      editor.generate_resource(@parser.properties[name])
      editor.fixup_properties(@parser.properties[name])
      editor.insert(BEFORE_CLASS, model_comments(name))
      editor.insert(AFTER_INCLUDES, '  include AssociationHelper')
      editor.insert(AFTER_INCLUDES, '  is_paginated')
      editor.insert(AFTER_REQUIREMENTS, def_to_s(@parser.properties[name]))
    end
  end
  
  # add the relationships to each model file
  def gen_relationships
    @parser.relationships.each do |rel|
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

  # add any "other" requirements as comments to the models
  def gen_requirements
    @parser.requirements.each do |name, value|
      editor = ModelEditor.new(name.snake_case)
      editor.insert(AFTER_RELATIONSHIPS, value.collect{|v| "  # #{v}"}.join("\n"))
    end
  end
  
  # generate the router.rb using RESTful routes for all models
  def gen_router
    filename = 'config/router.rb'
    bakname = 'config/router.rb~'
    File.delete(bakname) if File.exist?(bakname)
    File.rename(filename, bakname) if File.exist?(filename)
    File.open(filename, "w") do |file|
      file.puts(router_content)
    end
  end
  
  # add some comments to the generated request specs
  def gen_request_specs
    Dir.glob('spec/requests/*.rb').each do |filename|
      editor = RequestSpecEditor.new(filename)
      editor.add_directions
    end
  end
  
  # generate an config/init/app_config.rb file
  def gen_app_config_file
    filename = 'config/init/app_config.rb'
    bakname = 'config/init/app_config.rb~'
    File.delete(bakname) if File.exist?(bakname)
    File.rename(filename, bakname) if File.exist?(filename)
    File.open(filename, "w") do |file|
      file.puts(app_config_content)
    end
  end
  
  # the contents of the config/init/app_config.rb file
  def app_config_content
    buf = []
    buf << 'class AppConfig'
    buf << "  APP_NAME='#{@project_name.camel_case}'"
    buf << "  APP_CONTROLLERS=%w(#{@parser.descriptions.collect{|model| model.singularize.snake_case.pluralize}.join(' ')})"
    buf << 'end'
    buf.join("\n")
  end

  # geneate model comment from synopsis
  def model_comments(name)
    buf = []
    unless @parser.synopses[name].nil?
      @parser.synopses[name].each do |line|
        buf << "# #{line.gsub("'", '\'').gsub('"', '\"')}"
      end
    end
    buf
  end
  
  def gen_jeweler_rake
    g = Git.open('.')
    github_user = g.config('github.user')
    user_email = g.config('user.email')
    user_name = g.config('user.name')
    File.open('lib/tasks/jeweler.rake', 'w') do |file|
      file.puts <<END_JEWELER
begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "#{@project_name}"
    gemspec.summary = "TODO"
    gemspec.email = "#{user_email}"
    gemspec.homepage = "http://github.com/#{github_user}/#{@project_name}"
    gemspec.description = "TODO"
    gemspec.authors = ["#{user_name}"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end
END_JEWELER
    end
  end

  # generate the to_s method to add to a model class
  def def_to_s(properties)
    buf = []
    unless properties.nil?
      buf << '  def to_s'
      buf << "    buf = []"
      properties.each do |prop|
        name = prop[:variable].to_s
        buf << "    buf << \":#{name} => \" + send(\"#{name}\").inspect"
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
end
END_ROUTER_FOOTER

  # generate the replacement content for the config/router.rb file.
  def router_content
    buf = []
    buf << ROUTER_HEADER
    indent = 1
    new_routes = routes_fix_names(@parser.routes)
    @parser.descriptions.sort.each do |name|
      buf += find_route(indent, name, new_routes, @route_depth)
    end
    buf << ROUTER_FOOTER
    buf.join("\n")
  end
  
  # remove any unexpected routes
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
  
  # find the resource routes for the given name (model or controller)
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

