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

  #####################################################################
  ##### TODO change '_application_name' to the actual application name
  c[:session_id_key] = '_application_name_session_id' # cookie session id key, defaults to "_session_id"
  #####################################################################
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

# ==== Tune your inflector

# To fine tune your inflector use the word, singular_word and plural_word
# methods of Extlib::Inflection module metaclass.
#
# Here we define erratum/errata exception case:
#
# Extlib::Inflection.word "erratum", "errata"
#
# In case singular and plural forms are the same omit
# second argument on call:
#
# Extlib::Inflection.word 'information'
#
# You can also define general, singularization and pluralization
# rules:
#
# Once the following rule is defined:
# Extlib::Inflection.rule 'y', 'ies'
#
# You can see the following results:
# irb> "fly".plural
# => flies
# irb> "cry".plural
# => cries
#
# Example for singularization rule:
#
# Extlib::Inflection.singular_rule 'o', 'oes'
#
# Works like this:
# irb> "heroes".singular
# => hero
#
# Example of pluralization rule:
# Extlib::Inflection.singular_rule 'fe', 'ves'
#
# And the result is:
# irb> "wife".plural
# => wives

Extlib::Inflection.word 'address', 'addresses'
