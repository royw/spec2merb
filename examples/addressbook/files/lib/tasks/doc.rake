require 'yard'

namespace :doc do

# desc 'generate doc graphs'
# task :diagrams do
#  `yard-graph --full --dependencies | dot -Tsvg | sed 's/font-size:14.00/font-size:11.00/g' > doc/models.svg`
#   
# end

  namespace :diagram do
    desc 'generate model diagrams'
    # task :models => :merb_env do
    task :models do
      sh "railroad -i -l -a -m -M -v | neato -Tsvg | sed 's/font-size:14.00/font-size:11.00/g' > doc/models.svg"
    end

    desc 'generate controller diagrams'
    task :controllers => :merb_env do
      sh "railroad -i -l -C | neato -Tsvg | sed 's/font-size:14.00/font-size:11.00/g' > doc/controllers.svg"
    end
  end

  desc 'generate model and controller diagrams'
  task :diagrams => %w(diagram:models diagram:controllers)

  YARD::Rake::YardocTask.new do |t|
    t.files   = ['app/models/*.rb']   # optional
    t.options = ['--readme', 'README'] # optional '--any', '--extra', '--opts',
  end

end
