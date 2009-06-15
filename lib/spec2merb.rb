$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'extlib'
require 'ruby-debug'
require 'fileutils'
require 'versionomy'
require 'log4r'
require 'git'

include FileUtils::Verbose

require 'spec2merb/file_editor'
require 'spec2merb/model_editor'
require 'spec2merb/request_spec_editor'
require 'spec2merb/spec_parser'
require 'spec2merb/spec2_merb'
require 'spec2merb/exit_code'
require 'spec2merb/cli'
