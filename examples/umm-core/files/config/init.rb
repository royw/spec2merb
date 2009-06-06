# Go to http://wiki.merbivore.com/pages/init-rb

require 'config/dependencies.rb'

use_orm :datamapper
use_test :rspec
use_template_engine :haml

Merb::Config.use do |c|
  c[:use_mutex] = false
  c[:session_store] = 'cookie'  # can also be 'memory', 'memcache', 'container', 'datamapper

  # cookie session store configuration
  c[:session_secret_key]  = '26ded9f6891e4d7fb8fea3fb49fe3299f1405e6d'  # required for cookie session store
  c[:session_id_key] = '_umm-core_session_id' # cookie session id key, defaults to "_session_id"
end

Merb::BootLoader.before_app_loads do
  # This will get executed after dependencies have been loaded but before your app's classes have loaded.

  # load all the ruby files in config/init
  Dir.glob(File.join(File.dirname(__FILE__), "init", "*.rb")).each do |f|
    puts " - loading #{f}"
    load f
  end
end

Merb::BootLoader.after_app_loads do
  # This will get executed after your app's classes have been loaded.

  DataMapper.auto_migrate!
  DataMapper::Resource.descendants.each do |model|
    model.reset if model.respond_to? :reset
  end

  Dir.glob(File.join(File.dirname(__FILE__), "data", "*.rb")).each do |f|
    puts " - loading #{f}"
    load f
  end
end
