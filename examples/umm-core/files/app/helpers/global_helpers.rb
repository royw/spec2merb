module Merb
  module GlobalHelpers
    APPLICATION_NAME = 'UMM Core (demo)'
    MENU_BAR_CONTROLLERS = %w(sources filespecs commands media_objects genres languages titles years)

    # helpers defined here available to all views.

    def paginate_helper
      str = ''
      unless @current_page.nil? || @page_count.nil?
        if @page_count > 1
          str = paginate(@current_page, @page_count,
                          :outer_window => 5,
                          :next_label => "Next",
                          :prev_label => "Previous",
                          :default_css => false)
        end
      end
      str
    end

    # parent is an Array of model instances or nil
    def rest_resource(parent, *args)
      Merb.logger.info "rest_resource(#{parent.inspect}, #{args.inspect})"
      rsrc = nil
      if parent.nil?
        rsrc = resource(*args)
      else
        rsrc = resource(*([parent].flatten + (args || [])))
      end
      Merb.logger.info "rest_resource => #{rsrc}"
      rsrc
    end

    def has_rest_resource(parent, *args)
      valid_route = true
      begin
        rest_resource(parent, *args)
      rescue
        valid_route = false
      end
      valid_route
    end

#     def calendar_resource(parent, resource, collection)
#       rest_resource(parent, (resource || collection.to_sym), :calendar, :view => :month, :type => (collection || :appointments))
#     end

    # page banner
    def site_banner
      "<h1>#{APPLICATION_NAME}</h1>"
    end

    def user_info
      buf = []
      unless session[:user].blank?
        buf << list_item("<b>#{@user.to_s}</b>")
        buf << list_item(link_to('Logout', '/logout'))
      end
      div_class('login', ul(buf.join("\n")))
    end

    # a horizontal menu bar for the application
    def site_navigation
      buf = []
      buf << '<h2>Site Navigation</h2>'
      buf << '<ul>'
      MENU_BAR_CONTROLLERS.each do |name|
        if name =~ /^\/(.*)/
          buf << list_item(link_to($1.camel_case, name))
        else
#           if has_rest_resource(nil, name.to_sym, :calendar)
#             buf << list_item(link_to(name.camel_case, rest_resource(nil, name.to_sym, :calendar)))
#           else
            buf << list_item(link_to(name.camel_case, resource(name.to_sym)))
#           end
        end
      end
      buf << '</ul>'
      div_class('site_navigation', buf.join("\n"))
    end

    # returns a resource, either then last one in the session[:page_history]
    # stack or if none available, the resource specified in the args
    # def back_resource(*args)
    #   rsrc = resource(*args)
    #   session[:page_history] ||= []
    #   link = session[:page_history].last
    #   unless link.nil?
    #     rsrc = link[0] unless link[0].blank?
    #   end
    #   rsrc
    # end

    def history_navigation
      buf = []
      buf << "<h2>Site History</h2>"
      buf << "<ul>"
      unless session[:page_history].nil?
        session[:page_history].select{|link| !link[1].nil?}.each do |link|
          buf << list_item(link_to(link[1], link[0]))
        end
      end
      buf << "</ul>"
      div_id('history', buf.join("\n"))
    end

    # attempt to fix the problem where given the option :checked=>true
    # as per the documentation but needs to be :checked=>'checked'
    def radio_button(*args)
      opts = args.last
      opts[:checked] = "checked" if opts.is_a?(Hash) && opts.delete(:checked)
      super
    end

    # attempt to fix the problem where given the option :checked=>true
    # as per the documentation but needs to be :checked=>'checked'
    def radio_group(*args)
      opts = args.last
      opts[:checked] = "checked" if opts.is_a?(Hash) && opts.delete(:checked)
      super
    end

    # helper for creating a radio_group for an Enum
    # example:
    #   class FooBar
    #     property :foo, Enum[:a,:b,:c]
    #   end
    #   foobar = FooBar.first
    #   enum_radio_group(:foo, [:a,:b,:c], foobar.foo)
    def enum_radio_group(method, value_array, checked_value)
      rg_array = value_array.collect do |sym|
        options = {:value=>sym, :label=>sym.to_s}
        if checked_value.to_s == sym.to_s
          options[:checked] = 'checked'
        end
        options
      end
      radio_group method, rg_array
    end

    # helper for creating a radio group for an Enum data type
    def select_enum(title, method, values, selected)
      buf = []
      buf << div_class('label', label(title))
      buf << div_class('radio_group', enum_radio_group(method, values, selected))
      div_id('select_enum', buf.join("\n"))
    end

    # date selector composed of three (day, month, year) select boxes
    def select_date(title, base, base_attr_id)
      date = base.send(base_attr_id.to_s) || Time.now
      p ['date', date]
      month_attrs = {
        # :label => "#{title}:  ",
        :name => base_attr_id.to_s + '_date[month]',
        # :id => base_attr_id.to_s + '_month',
        :collection => %w(1 2 3 4 5 6 7 8 9 10 11 12),
        :selected => date.month.to_s
      }
      day_attrs = {
        :name => base_attr_id.to_s + '_date[day]',
        :collection => (1..31).to_a.collect{|n| n.to_s},
        :selected => date.day.to_s
      }
      year_attrs = {
        :name => base_attr_id.to_s + '_date[year]',
        :collection => (1970..2020).to_a.collect{|n| n.to_s},
        :selected => date.year.to_s
      }
      label(title) +
      select(base_attr_id.to_sym, month_attrs) +
      select(base_attr_id.to_sym, day_attrs) +
      select(base_attr_id.to_sym, year_attrs)
    end

    def select_datetime(title, base, base_attr_id)
      buf = []
      buf << text_field(:name => base_attr_id,
                        :label => title,
                        :id => base_attr_id,
                        :class => 'DatePicker',
                        :tabindex => "1",
                        :value => "10/24/2009")
      buf << div_class('instructions', 'hh:mm MM/DD/YYYY')
      div_id('date_selector', buf.join("\n"))
    end

    # select_belongs_to('State', @address, :state_id, State, :name)
    def select_belongs_to(title, base, base_attr_id, type, text_method)
      # Merb.logger.info "select_belongs_to(#{title.inspect}, #{base.inspect}, #{base_attr_id.inspect}, #{type.inspect}, #{text_method.inspect})"
      selected = base.send(base_attr_id).to_s
      # Merb.logger.info "  selected => #{selected}"
      select base_attr_id.to_sym,
             :label => "#{title}:  ",
             :text_method => text_method.to_sym,
             :value_method => :id,
             :collection => type.all.sort{|a,b| a.send(text_method.to_s) <=> b.send(text_method.to_s)},
             :selected => selected
    end

    def show_all_associations(obj)
    end

    # show associations as a list
    def show_associations(title, base, association)
      buf = []
      buf << "<h3>#{title}</h3>"
      buf << "<ul>"
      base.send(association.to_s.singularize.pluralize).each do |item|
        buf << list_item(show_attribute(nil, item.to_s.camel_case, item))
      end
      buf << "</ul>"
      buf.join("\n")
    end

    # new association button
    def new_association(title, base, association)
      unless base.new_record?
        ul(list_item("#{new_btn(resource(base, association.to_s.singularize.pluralize.to_sym, :new), 'New ' + title)}"))
      end
    end

    LABEL_WIDTH = 30
    VALUE_WIDTH = 50

    # limit the given string to len characters and append three dots if string is clipped
    def limit(value,len)
      s = value.to_s
      if s.length > len
        s = s[0..(len-1)] + "..."
      end
      s
    end

    def edit_properties(obj)
      buf = []
      afields = attribute_fields(obj)
      afields.each do |field|
        buf << list_item(edit_text(field.to_s.camel_case, field))
      end
      b2fields = belongs_to_fields(obj)
      unless b2fields.empty?
        buf << list_item(show_belongs_to(obj, b2fields))
      end
      p ['attribute_fields', afields]
      p ['belongs_to_fields', b2fields]
      p ['edit_properties => ', buf]
      buf.join("\n")
    end

    def show_properties(obj)
      buf = []
      attribute_fields(obj).each do |field|
        buf << list_item(show_attribute(field.to_s.camel_case, obj.send(field), obj))
      end
      b2fields = belongs_to_fields(obj)
      unless b2fields.empty?
        buf << list_item(show_belongs_to(obj, b2fields))
      end
      buf.join("\n")
    end

    def belongs_to_fields(obj)
      found_fields = []
      fields = obj.send('properties').collect do |property|
        field = property.field
        field = $1 if field =~ /(.*)_id$/
        field
      end
      fields.uniq.each do |field|
        next if field == 'id'
        rel = obj.send('relationships')[field]
        if !rel.nil? && rel.options.empty?
          found_fields << field.to_sym
        end
      end
      found_fields
    end

    def attribute_fields(obj)
      found_fields = []
      fields = obj.send('properties').collect do |property|
        field = property.field
        field = $1 if field =~ /(.*)_id$/
        field
      end
      fields.uniq.each do |field|
        next if field == 'id'
        rel = obj.send('relationships')[field]
        unless !rel.nil? && rel.options.empty?
          found_fields << field.to_sym
        end
      end
      found_fields
    end

    # label: value [show] [edit] [delete]
    def show_attribute(title, value, obj=nil)
      buf = []
      value = value.hhmm_mmddyyyy if value.kind_of? Time
      if obj.nil?
        buf << div_class('label', h(limit(title, LABEL_WIDTH))) unless title.nil?
        buf << div_class('value', h(limit(value, VALUE_WIDTH))) unless value.nil?
      else
        buf << div_class('label', h(limit(title, LABEL_WIDTH))) unless title.nil?
        buf << div_class('value', h(limit(value, VALUE_WIDTH))) unless value.nil?
        buf << div_class('buttons', edit_buttons(obj))
      end
      div_class("#{cycle('even', 'odd')}", div_id('attribute', buf.join("\n")))
    end

    def show_boolean(title, value)
      show_attribute(title, value ? 'Yes' : 'No')
    end

    def show_connections(obj, fields=nil)
      unless obj.id.blank?
        if fields.nil?
          fields = []
          dm_model = DM_Model.new(obj.class)
          dm_model.edges.each do |edge|
            # edge is an Array => [assoc_type, class_name, assoc_class_name, assoc_name]
            p ['edge', edge]
            fields << edge[3].to_sym
          end
        end
        p ['show_connections fields => ', fields]
        label = "<h3>Connected To</h3>"
        items = []
        fields.sort{|a,b| a.to_s <=> b.to_s}.each do |field|
          begin
            items << list_item(show_btn(rest_resource(obj,field), h(field.to_s.camel_case)))
          rescue Exception => e
            puts e.to_s
          end
        end
        div_id(:connected_to, label + paragraph(ul(items)))
      end
    end

    def show_photo(title, photo)
      result = ''
      unless photo.nil?
        buf = []
        buf << list_item(div_class('title', title))
        buf << list_item(image_tag(photo.filepath))
        result = div_class('photo', ul(buf.join("\n")))
      end
      result
    end

    def show_belongs_to(obj, fields)
      label = "<h3>Belongs To</h3>"
      items = []
      fields.each do |field|
        owner = obj.send(field)
        items << list_item(show_attribute(h(field.to_s.camel_case + ':'), h(limit(owner.to_s, VALUE_WIDTH)), owner))
      end
      div_id(:belongs_to, label + paragraph(div_id(:attribute, ul(items))))
    end

    def edit_text(title, value)
      div_class('text_field', text_field(value, :label => title))
    end

    def edit_checkbox(title, value)
      div_class('check_box', check_box(value, :label => "&nbsp;&nbsp;#{title}"))
    end

    def edit_boolean(title, name, value)
      div_class('check_box', check_box(:name => name, :value => value, :label => "&nbsp;&nbsp;#{title}"))
    end

    def edit_buttons(obj)
      buf = []
      buf << list_item(delete_btn(rest_resource(@parent, obj, :delete), 'Delete'))
      buf << list_item(edit_btn(rest_resource(@parent, obj, :edit), 'Edit'))
      buf << list_item(show_btn(rest_resource(@parent, obj), 'Show'))
#       buf << list_item(show_btn(rest_resource(obj, :calendar), 'Calendar')) if has_rest_resource(obj, :calendar)
      ul(buf.join)
    end

    def edit_btn(action, title='Edit')
      buf = []
      buf << link_to(title, action)
      buf.join
    end

    def show_btn(action, title='Show')
      buf = []
      buf << link_to(title, action)
      buf.join
    end

    def new_btn(action, title='New')
      buf = []
      buf << link_to(title, action)
      buf.join
    end

    def delete_btn(action, title='Delete')
      buf = []
      buf << link_to(title, action)
      buf.join
    end

    def list_item(str)
      "<li>#{str}</li>"
    end

    def ul(str)
      "<ul>\n#{str}\n</ul>"
    end

    def ol(str)
      "<ol>\n#{str}\n</ol>"
    end

    def paragraph(str)
      "<p>#{str}</p>"
    end

    def fieldset(str)
      "<fieldset>\n#{str}\n</fieldset"
    end

    def input(opts={})
      buf = []
      opts.each do |k, v|
        buf << "#{k.to_s}=\"#{v.to_s}\""
      end
      "<input #{buf.join(' ')} />"
    end

    # return: <div class="class_name">text</div>
    def div_class(class_name, text)
      "<div class='#{class_name.to_s}'>#{text}</div>"
    end

    # return: <div id="id_name">text</div>
    def div_id(id_name, text)
      "<div id='#{id_name.to_s}'>#{text}</div>"
    end

    # return: <div id="id_name" class="class_name">text</div>
    def div_id_class(id_name, class_name, text)
      "<div id='#{id_name.to_s}' class='#{class_name.to_s}'>#{text}</div>"
    end


    class DM_Model
      def initialize(klass)
        @klass = klass
        # Processed habtm associations
        @habtm = []
      end

      # return the model edges (relationships)
      def edges
        found_edges = []
        # Process class relationships
        relationships = @klass.relationships
#         p ['relationships', relationships]
#         if @options.inheritance && ! @options.transitive
#           if @klass.superclass.respond_to?'relationships'
#             superclass_relationships = @klass.superclass.relationships
#             relationships = relationships.select{|k,a| superclass_relationships[k].nil?}
#           end
#         end
        remove_joins(relationships).each do |k, a|
          found_edges << process_relationship(@klass.name, a)
        end
#         p ['found_edges', found_edges]
        found_edges.compact
      end

      def belongs_tos
        found_edges = []
        # Process class relationships
        @klass.relationships.select{ |relationship| relationship.options.empty? }
      end

      protected

      # datamapper's relationships for HABTM fully map the relationship
      # from each end.  We do not want to duplicate relationship arrows
      # on the graph, so remove the duplicates here.
      def remove_joins(relationships)
        new_relationships = {}
        join_names = []
        relationships.each do |k,v|
          if v.kind_of? DataMapper::Associations::RelationshipChain
            join_names << v.name
          end
        end
        relationships.each do |k,v|
          unless join_names.include? k
            new_relationships[k] = v
          end
        end
        new_relationships
      end

      # Process a model association
      def process_relationship(class_name, relationship)
        #STDERR.print "\t\tProcessing model relationship #{relationship.name.to_s}\n" if @options.verbose

        assoc_type = nil
        # Skip "belongs_to" relationships
        unless relationship.options.empty?
          # Only non standard association names needs a label
          assoc_class_name = (relationship.child_model.respond_to? 'underscore') ?
                                relationship.child_model.underscore.singularize.camelize :
                                relationship.child_model
          if assoc_class_name == relationship.name.to_s.singularize.camel_case
            assoc_name = ''
          else
            assoc_name = relationship.name.to_s
          end

          assoc_type = nil
          if has_one_relationship?(relationship)
            assoc_type = 'one-one'
          elsif has_many_relationship?(relationship) && !has_through_relationship?(relationship)
            assoc_type = 'one-many'
          elsif has_many_relationship?(relationship) && has_through_relationship?(relationship)
            if relationship.kind_of? DataMapper::Associations::RelationshipChain
              assoc_name = relationship.options[:remote_relationship_name]
            end
            return if @habtm.include? [relationship.child_model, class_name, assoc_name]
            assoc_type = 'many-many'
            @habtm << [class_name, relationship.child_model, assoc_name]
          end
        end
        assoc_type.nil? ? nil : [assoc_type, class_name, assoc_class_name, assoc_name]
      end # process_association

      # is this relationship a has n, through?
      def has_through_relationship?(relationship)
        result = false
        # names are symbols
        near_name = relationship.options[:near_relationship_name]
        remote_name = relationship.options[:remote_relationship_name]
        unless near_name.nil? || remote_name.nil?
          # ok, both near and remote have names
          result = (near_name != remote_name)
        end
        result
      end

      # is this relationship a has 1?
      def has_one_relationship?(relationship)
        (relationship.options[:min] == 1) && (relationship.options[:max] == 1)
      end

      # is this relationship a has n?
      def has_many_relationship?(relationship)
        !relationship.options[:max].nil? && (relationship.options[:max] != 0) && (relationship.options[:max] != 1)
      end
    end
  end

end


