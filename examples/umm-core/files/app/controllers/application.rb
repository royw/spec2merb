# date fields are supported as follows
# 1) use global_helpers select_date or select_datetime
# 2) do not name any properties with a name ending in "_date"
# 3) the select_date/datetime's base_attr_id should be the property name of a property of type Date or DateTime
# 4) select_date/datetime will return a hash that is named "#{base_attr_id}_date"
# 5) the update method will call update_dates which will parse the hash and set the value

class Application < Merb::Controller

  #before :ensure_authenticated
  #before :get_user
  @@page_size = 25

  def debug(name)
    Merb.logger.info "**** #{name} ****"
    Merb.logger.info "session => #{session.inspect}"
    Merb.logger.info "params => #{params.inspect}"
  end

  def set_title(title)
    session[:prev_title] = session[:title]
    session[:title] = title
    back_navigation
  end

  public

  class <<self
    def paginate(page_size = 25)
      @@page_size = page_size
    end
  end

  def index
    debug 'index'
    set_title controller_name.camel_case
    get_parent
    display_collection
  end

  def show
    debug 'show'
    set_title resource_class_name
    get_parent
    get_resource
    display_form @resource
  end

  def new
    debug 'new'
    set_title 'New ' + resource_class_name
    get_parent
    new_resource
    update_relations
    setup_date_variables
    only_provides :html
    display_form @resource
  end

  def edit
    debug 'edit'
    set_title 'Edit ' + resource_class_name
    get_parent
    get_resource
    setup_date_variables
    only_provides :html
    display_form @resource
  end

  def create
    debug 'create'
    get_parent
    new_resource
    attrs = get_attributes
    # Merb.logger.info {"attrs => #{attrs.inspect}"}
    begin
      raise Exception.new('error updating attributes') unless get_resource.update_attributes(attrs) 
      raise Exception.new('error updating relations') unless update_relations 
      raise SaveException.new(@resource, 'error saving resource') unless @resource.save
      show_resource = rest_resource(@parent, @resource)
      # append the format if it's available
      show_resource += ".#{params[:format]}" unless params[:format].blank?
      redirect show_resource #, :message => {:notice => "#{resource_class_name} was successfully created"}
    rescue Exception => e
      Merb.logger.error { "Error in create: " + e.to_s }
      # display error messages and reload "new" page
      if @resource.errors.empty?
        raise NotAcceptable
      else
        # TODO this doesn't seem right for a non html format (new is html only)
        redirect rest_resource(@parent, controller_name, :new), :message => {:error => @resource.errors.values.join(", ")}
      end
    end
  end

  def update
    debug 'update'
    get_parent
    if get_resource.update_attributes(get_attributes) && update_relations && @resource.save
      redirect rest_resource(@parent, @resource)
    else
      # display error messages and reload "edit" page
      if @resource.errors.empty?
        raise NotAcceptable
      else
        redirect rest_resource(@parent, @resource, :edit), :message => {:error => @resource.errors.values.join(", ")}
      end
    end
  end

  def destroy
    debug 'destroy'
    get_parent
    if get_resource.destroy
      redirect rest_resource(@parent, controller_name.to_sym)
    else
      raise InternalServerError
    end
  end

  def delete(id)
    # destroy #(id)
    debug 'delete'
    set_title resource_class_name
    get_parent
    get_resource
    only_provides :html
    display_form @resource
  end

  protected

  def parent_opts
    opts = {}
    unless @parent.nil?
      @parent.each do |obj|
        name = obj.class.name.snake_case
        opts["#{name}_id".to_sym] = obj.id
      end
    end
    opts
  end

  def resource_opts
    opts = {}
    unless @resource.nil?
      opts["#{@resource.class.name.snake_case}_id"] = params['id']
    end
    opts
  end

  def update_relations
    result = true
    unless @parent.nil?
      parent = @parent.last
      singular_name = parent.class.name.snake_case
      plural_name = singular_name.pluralize
      if @resource.respond_to? "#{singular_name}="
        # puts "1:n via #{singular_name}"
        @resource.send("#{singular_name}=", parent)
      elsif @resource.respond_to? plural_name
        # puts "n:n via #{plural_name}"
#        eval "@resource.#{plural_name}.push parent"
        @resource.send(plural_name).send('push', parent)
      end
    end
    result
  end

  def setup_date_variables
    resource_class.properties.each do |property|
      unless property.type == DateTime
        unless (property.name == 'created_at') || (property.name == 'updated_at')
          instance_variable_set(:"@#{property.name}_date", Hash.new)
        end
      end
    end
  end

  def get_parent
    if @parent.nil?
      params.each do |k, v|
        if k.to_s =~ /(.+)_id/
          @parent ||= []
          @parent << find_resource($1.camel_case, v)
          p ['@parent', @parent.inspect]
        end
      end
    end
    @parent
  end

  def get_user
    Merb.logger.info 'get_user'
    if @user.nil?
      session.each do |k, v|
        Merb.logger.info "k => #{k}, v => #{v.inspect}"
        if k.to_s == 'user'
          @user = User.first(:id => v)
        end
      end
    end
    Merb.logger.info "user => #{@user.inspect}"
    @user
  end

  def get_resource
    get_parent
    params.each do |k, v|
      if k.to_s == 'id'
        @resource = find_resource(resource_class_name, v)
      end
    end
    @resource
  end

  def get_collection
    name = controller_name.snake_case

    @collection = if @parent
                    @parent.last.send(name.to_sym)
                  else
                    resource_class.all(sort_options)
                  end

    # if @@page_size
    #   @collection = @collection.paginate(:page => params[:page], :per_page => @@page_size)
    # end
    if @@page_size
      @current_page = (params[:page] || 1).to_i
      @page_count, @collection = @collection.paginated(
        {
          :page => @current_page,
          :per_page => @@page_size
        }.merge sort_options
      )
    end

    instance_variable_set(:"@#{name}", @collection)
  end

  def get_attributes
    params[resource_class_name.snake_case.to_sym] || {}
  end

  def new_resource
    @resource = resource_class.new(get_attributes)
    instance_variable_set(:"@#{resource_class_name.snake_case}", @resource)
  end

  def display_collection
    display_form get_collection
  end

  def find_resource(class_name, id)
    resource = Kernel.const_get(class_name).get!(id)
    instance_variable_set(:"@#{class_name.snake_case}", resource)
  end

  def resource_class_name
    controller_name.singular.camel_case
  end

  def resource_class
    Kernel.const_get(resource_class_name)
  end

  def display_form(object, thing = nil, opts = {})
    unless @parent.nil?
      @parent.each {|parent| opts.merge!("#{parent.class.name.snake_case}_id" => parent.id)}
    end
    if resource_class.respond_to?('form_definition')
      template_opt = thing.is_a?(Hash) ? thing.delete(:template) : opts.delete(:template)

      case thing
      # display @object, "path/to/foo" means display @object, nil, :template => "path/to/foo"
      when String
        template_opt, thing = thing, nil
      # display @object, :template => "path/to/foo" means display @object, nil, :template => "path/to/foo"
      when Hash
        opts, thing = thing, nil
      end

      # Try to render without the object
      # Merb.logger.info "render_form opts=>#{opts.inspect}"
      render_form(thing || action_name.to_sym, opts.merge(:template => template_opt))
    else
      # Merb.logger.info "display opts=>#{opts.inspect}"
      display(object, thing, opts)
    end
  end

  def sort_options
    {}
  end

  # maintain a back trace stack in session[:page_history], removing
  # any path loops.  back_resource() in global_helper will then
  # use session[:page_history].
  def back_navigation
    # session[:last_page] = nil
    session[:page_history] ||= []
    # session[:page_history].delete ''
    previous_page = request.env['HTTP_REFERER']
    current_page = (request.env['rack.url_scheme'] + '://' + request.env['HTTP_HOST'] + request.env['REQUEST_PATH']).to_s
    unless previous_page.nil?
      # remove trailing / and any params
      prev_link = [previous_page.to_s.gsub(/\/$/, '').gsub(/\?.*/, ''), session[:prev_title]]
      session[:page_history] << prev_link
      # do a little cleanup, mostly for development session
      session[:page_history].compact!
      session[:page_history].uniq!
      session[:page_history] = session[:page_history].select{|link| link.kind_of? Array }

      # if the current link is already in the page history, then delete all history after it.
      # remove trailing / and any params
      curr_link = [current_page.gsub(/\/$/, '').gsub(/\?.*/, ''), session[:title]]
      index = nil
      session[:page_history].each do |link|
        if (link[0] == curr_link[0]) || (link[1] == curr_link[1])
          index = session[:page_history].index(link)
          break
        end
      end
      unless index.nil?
        if index == 0
          session[:page_history].clear
        else
          session[:page_history] = session[:page_history][0..(index - 1)]
        end
      end
    end
  end

end




