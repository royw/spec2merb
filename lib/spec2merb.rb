$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'extlib'
require 'ruby-debug'
require 'fileutils'
require 'versionomy'
require 'log4r'

include FileUtils::Verbose

require 'file_editor'
require 'model_editor'
require 'request_spec_editor'
require 'spec2_merb'
require 'exit_code'
require 'cli'
