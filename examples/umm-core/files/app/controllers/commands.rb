# The REST methods are in the Application controller.
# You will probably want to def the sort_options here.
class Commands < Application
# provides :xml, :yaml, :js
# def sort_options
#    {:order => [:name.asc]}
# end
  provides :xml

  def create
    params.delete 'started_at' if params.keys.include?('started_at')
    params.delete 'finished_at' if params.keys.include?('finished_at')
    attrs = get_attributes
    Merb.logger.info {"attrs => #{attrs.inspect}"}
    run_later do
      (1..10).step(1) do
        Merb.logger.info {'**************************************'}
        sleep(1) # give the record a chance to be created
        cmd = Command.first(:name => attrs['name'])
        unless cmd.nil?
          Merb.logger.info {"cmd => #{cmd.to_s}"}
          run_command(cmd)
          break
        end
      end
    end
    super
  end
  
  # Runs the given command.
  # cmd is a Command instances.  It can not be nil.
  # cmd.command is the name of the background process run.
  # 'BackgroundProcess::' + cmd.command is the class name of the background process to run.
  # Each BackgroundProcess is required to take the Command instance as the constructor parameter.
  # Each BackgroundProcess is required to have a 'run' method.
  def run_command(cmd)
    begin
      cmd.started_at = DateTime.now
      cmd.finished_at = nil
      cmd.status = 'Running'
      cmd.save
    
      name = cmd.process.camel_case
      command_name = "BackgroundProcess::#{name}"
      Merb.logger.info { "\ncommand_name => #{command_name}\n" }
      if available_commands.include?(name)
        process = Object.full_const_get(command_name).new(cmd)
        process.run
        cmd.status = 'Completed'
        cmd.save
      else
        raise Exception.new('Invalid Command')
      end
      Merb.logger.info { "************* finished running #{cmd.to_s}" }
    rescue Exception => e
      cmd.status = e.to_s
      cmd.save
      Merb.logger.error { "\n****\n**** Error: " + e.to_s + "\n****\n" }
    ensure
      cmd.finished_at = DateTime.now
      cmd.save
    end
  end
  
  def available_commands
    # only find the background_processes once
    @background_processes ||= BackgroundProcess.constants.select do |name| 
      Object.full_const_get("BackgroundProcess::#{name}").instance_methods.include?('run')
    end
    @background_processes
  end
end
