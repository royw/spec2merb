namespace :dev do
  namespace :gen do
    TEMPLATE_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'app', 'views', 'templates'))
    VIEWS_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'app', 'views'))
    GEN_VIEW_USAGE = 'usage: rake action="all|show|edit|new|delete|index" controllers="plural_name{,...}" dev:gen:view'
    ALL_CONTROLLERS = (Dir.glob("app/controllers/*.rb").collect{|name| File.basename(name, '.*')} - ['application', 'exceptions']).join(',')

    def update_template(template, view_dir, var_singular, var_plural)
      file_name = "#{template}.html.haml"
      src_file = File.join(TEMPLATE_PATH, file_name)
      if File.exist?(src_file)
        dest_file = File.join(view_dir, file_name)
        bak_name = file_name + '~'
        bak_file = File.join(view_dir, bak_name)
        puts "#{dest_file}"

        File.delete(bak_file) if File.exist?(bak_file)
        File.rename(dest_file, bak_file) if File.exist?(dest_file)
        File.open(dest_file, "w") do |file|
          IO.foreach(src_file) do |line|
            file.puts line.gsub(/var_singular/, var_singular).gsub(/var_plural/, var_plural)
          end
        end
      else
        puts "missing source template: #{src_file}"
      end
    end

    task :dummy do
    end

    desc "generate default views, #{GEN_VIEW_USAGE}"
    # task :view => :merb_env do
    task :view do
      action = ENV['action']
      controllers = ENV['controllers']
      puts "action => #{action}"
      puts "controllers => #{controllers}"
      if controllers.blank?
        controllers = ALL_CONTROLLERS
      end
      unless action.blank? || controllers.blank?
        if %w(all show edit new delete index).include? action
          controllers.split(/[\s,]/).each do |names|
            view_dir = File.join(VIEWS_PATH, names)
            if File.exist?(view_dir) && File.directory?(view_dir)
              if action == 'all'
                %w(_form _show show edit new delete index).each do |t|
                  update_template(t, view_dir, names.singular, names)
                end
              else
                update_template(action, view_dir, names.singular, names)
              end
            else
              puts "Invalid environment, view_dir => #{view_dir}"
            end
          end
        else
          puts "Invalid action"
        end
      else
        puts GEN_VIEW_USAGE
      end
    end

  end
end
