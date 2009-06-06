module AssociationHelper

  def add_association(name, key, value_hash)
    Merb.logger.info { "******* add_association(#{name}, #{key}, #{value_hash.inspect})" }
    values = value_hash[key] || value_hash[name]
    opts = value_hash
    opts.delete(key)
    opts.delete(name)
    unless values.blank?
      klass = ::Object.full_const_get(name.to_s.singularize.camel_case)
      if self.send(name).respond_to?('push')
        # association acts as an array
        values.each do |value|
          child = get_child(klass, key, value, opts)
          self.send(name).push(child) unless child.nil?
        end
      else
        # association does not act as an array
        child = get_child(klass, key, values, opts)
        self.send(name.to_s + '=', child)
      end
    end
  end

  protected
  
  def get_child(klass, key, values, opts)
    parameters = {key => values}.merge(opts)
    valid_propnames = klass.properties.collect{|prop| prop.name}
    parameters.keys.each do |propname|
      parameters.delete(propname) unless valid_propnames.include?(propname)
    end
    klass.first(parameters) || klass.create(parameters)
  end

end
