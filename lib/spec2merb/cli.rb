require 'commandline/optionparser'

# == Synopsis
# The Command Line Interface
class CLI

  # == Synopsis
  # Here's the main execution loop
  def self.execute(stdout, arguments=[])
    exit_code = ExitCode::OK

    begin
      logger = setup_logger

      # parse the command line
      options = setup_parser()
      od = options.parse(arguments)
      reinitialize_logger(logger, od["--quiet"], od["--debug"])
      check_git_options
      
      project_name = od["--project"]
      raise ArgumentError.new('Missing --project name argument') if project_name.blank?
      
      specfile = od["--spec"]
      raise ArgumentError.new('Missing --spec specfile argument') if specfile.blank?
      raise ArgumentError.new("Invalid --spec specfile argument, #{specfile} does not exist") unless File.exist?(specfile)
      
      install = true
      install = false if od["--no_install"]
      
      route_depth = 2
      unless od['--depth'].blank?
        route_depth = od['--depth'].to_i
      end
      
      skip_execution = false
      %w(--help --version).each {|flag| skip_execution = true if od[flag] }
      unless skip_execution
        # create and execute class instance here
        app = Spec2Merb.new(project_name, specfile)
        app.route_depth = route_depth
        logger.info { "Generating project" }
        app.generate(IO.read(specfile))
        logger.info { "Project generated" }
        if install
          logger.info { "Installing project" }
          app.install 
          logger.info { "Project installed" }
        end
        app.commit_and_merge
        logger.info { "You may want to examine lib/tasks/jeweler.rake for accuracy\n" }
        logger.info { "See http://github.com/guides/import-an-existing-git-repo for exporting to github" }
        logger.info { "Done" }
      end
    rescue ArgumentError => argErr
      logger.error {argErr.to_s}
      logger.error {options.to_s}
      logger.error {argErr.backtrace.join("\n")}
      exit_code = ExitCode::CRITICAL
    rescue Exception => eMsg
      logger.error {eMsg.to_s}
      logger.error {options.to_s}
      logger.error {eMsg.backtrace.join("\n")}
      exit_code = ExitCode::CRITICAL
    end
    exit_code
  end
  
  def self.check_git_options
    missing_options = []
    %w(user.name user.email github.user).each do |name|
      value = "git config #{name}".strip
      if value.blank?
        missing_options << name
      end
    end
    unless missing_options.empty?
      buf = []
      buf << "WARNING: You have not set your git #{missing_options.join(", ")} option(s).  Please run:"
      missing_options.each do |name|
        buf << "  git config --global #{name} value"
      end
      buf << "where value is your information"
      raise StandardError.new(buf.join("\n"))
    end
  end

  # == Synopsis
  # Setup the command line option parser
  # Returns:: OptionParser instances
  def self.setup_parser()
    options = CommandLine::OptionParser.new()

    # flag options
    [
      {
        :names           => %w(--version -v),
        :opt_found       => lambda {Log4r::Logger['spec2merb'].info{"Spec2Merb #{Spec2Merb::VERSION}"}},
        :opt_description => "This version of spec2merb"
      },
      {
        :names           => %w(--help -h),
        :opt_found       => lambda {Log4r::Logger['spec2merb'].info{options.to_s}},
        :opt_description => "This usage information"
      },
      {
        :names           => %w(--quiet -q),
        :opt_description => 'Display error messages only'
      },
      {
        :names           => %w(--debug -d),
        :opt_description => 'Display debug messages'
      },
      {
        :names           => %w(--no_install -n),
        :opt_description => 'Just generate the project, do not prep the database or install the gems'
      },
    ].each { |opt| options << CommandLine::Option.new(:flag, opt) }

    # non-flag options
    [
      {
        :names           => %w(--project -p),
        :arity           => [1,1],
        :arg_description => 'name',
        :opt_description => 'The name of the project to create (required)',
        :opt_found       => CommandLine::OptionParser::GET_ARGS
      },
      {
        :names           => %w(--spec -s),
        :arity           => [1,1],
        :arg_description => 'specfile',
        :opt_description => 'The .spec file that defines the project (required)',
        :opt_found       => CommandLine::OptionParser::GET_ARGS
      },
      {
        :names           => %w(--depth -r),
        :arity           => [1,1],
        :arg_description => 'n',
        :opt_description => 'The depth of restful routes to generate in config/router.rb (default=2)',
        :opt_found       => CommandLine::OptionParser::GET_ARGS
      },
      {
        :names           => %w(--output_level -l),
        :arity           => [1,1],
        :arg_description => 'level',
        :opt_description => 'Output logging level: DEBUG, INFO, WARN, ERROR. Default = INFO',
        :opt_found       => CommandLine::OptionParser::GET_ARGS
      }
    ].each { |opt| options << CommandLine::Option.new(opt) }

    options
  end

  # == Synopsis
  # Initial setup of logger
  def self.setup_logger
    logger = Log4r::Logger.new('spec2merb')
    logger.outputters = Log4r::StdoutOutputter.new(:console)
    Log4r::Outputter[:console].formatter  = Log4r::PatternFormatter.new(:pattern => "%m")
    logger.level = Log4r::DEBUG
    logger
  end

  # == Synopsis
  # Reinitialize the logger using the loaded config.
  # logger:: logger for any user messages
  # config:: is the application's config hash.
  def self.reinitialize_logger(logger, quiet, debug)
    Log4r::Outputter[:console].level = Log4r::INFO
    Log4r::Outputter[:console].level = Log4r::WARN if quiet
    Log4r::Outputter[:console].level = Log4r::DEBUG if debug
    Log4r::Outputter[:console].formatter = Log4r::PatternFormatter.new(:pattern => "%m")
    # logger.trace = true
    logger
  end
end

