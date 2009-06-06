
class Users < Application
  def sort_options
    {:order => [:login.asc]}
  end

  def new
    debug 'new'
    set_title 'New ' + resource_class_name
    get_parent
    new_resource
    @resource.old_password = nil
    @resource.new_password = ''
    @resource.confirm_password = ''
    setup_date_variables
    only_provides :html
    display_form @resource
  end

  def edit
    debug 'edit'
    set_title 'Edit ' + resource_class_name
    get_parent
    get_resource
    @resource.old_password = ''
    @resource.new_password = ''
    @resource.confirm_password = ''
    setup_date_variables
    only_provides :html
    display_form @resource
  end

  def create
    debug 'create'
    get_parent
    new_resource

    unless set_password
      redirect rest_resource(@parent, :users), :message => {:error => "Invalid new and confirm passwords"}
    else
      setup_date_variables
      if @resource.save && update_relations
        redirect rest_resource(@parent, @resource), :message => {:notice => "#{resource_class_name} was successfully created"}
      else
        redirect rest_resource(@parent, :users), :message => {:error => "Invalid user name"}
      end
    end
  end

  def update
    debug 'update'
    get_parent
    get_resource

    old_pw = params['user']['old_password']
    Merb.logger.info "old_password => #{old_pw}"
    # unless User.validate_password(old_pw, @resource.crypted_password, @resource.salt)
    unless @user.authenticated?(old_pw)
      redirect rest_resource(@parent, :users), :message => {:error => "Invalid old password"}
    else
      unless set_password
        redirect rest_resource(@parent, :users), :message => {:error => "Invalid new and confirm passwords"}
      else
        if update_dates && get_resource.update_attributes(get_attributes)
          redirect rest_resource(@parent, @resource)
        else
          raise NotAcceptable
        end
      end
    end
  end

  private

  def set_password
    new_pw = params['user']['new_password']
    confirm_pw = params['user']['confirm_password']
    Merb.logger.info "new_password => #{new_pw}"
    Merb.logger.info "confirm_password => #{confirm_pw}"
    @resource.password = new_pw
    @resource.password_confirmation = confirm_pw
    !new_pw.blank? && !confirm_pw.blank? && (new_pw == confirm_pw) && @resource.save
  end
end
