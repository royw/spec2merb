
  def to_s
    buf = []
    buf << self.titles.first.to_s unless self.titles.blank?
    buf << self.years.all.collect{|year| year.to_s}.join(', ') unless self.years.blank?
    buf << self.identifications.all.collect{|ident| ident.to_s}.join(', ') unless self.identifications.blank?
    buf << self.genres.all.collect{|genre| genre.to_s}.join(', ') unless self.genres.blank?
    buf.join(', ')
  end

  LOOKUP = {
    :directors        => lambda{|obj, value_hash| obj.send('add_directors', value_hash[:directors])},
    :actor            => lambda{|obj, value_hash| obj.send('add_actor', value_hash[:actor], value_hash[:character])},
    :exact_title      => lambda{|obj, value_hash| obj.send('add_association', :titles, :exact_title, value_hash)},
    :ratings          => lambda{|obj, value_hash| obj.send('add_association', :ratings, :value, value_hash)},
    :certifications   => lambda{|obj, value_hash| obj.send('add_association', :certifications, :value, value_hash)},
    :identifications  => lambda{|obj, value_hash| obj.send('add_association', :identifications, :value, value_hash)},
    :identifications  => lambda{|obj, value_hash| obj.send('add_association', :identifications, :value, value_hash)},
    :years            => lambda{|obj, value_hash| obj.send('add_association', :years, :value, value_hash)},
    :genres           => lambda{|obj, value_hash| obj.send('add_association', :genres, :name, value_hash)},
    :plots            => lambda{|obj, value_hash| obj.send('add_association', :plots, :description, value_hash)},
    :taglines         => lambda{|obj, value_hash| obj.send('add_association', :taglines, :description, value_hash)},
    :runtimes         => lambda{|obj, value_hash| obj.send('add_association', :runtimes, :seconds, value_hash)}
  }

  def <<(value_hash)
    value_hash.keys.each do |key|
      if LOOKUP[key]
        LOOKUP[key].call(self, value_hash)
        break
      end
    end
  end

  protected

  def add_directors(director_names)
    director_names.each do |director_name|
      Merb.logger.info { "****** add_director :director => #{director_name}" }
      person = Person.first(:name => director_name) || Person.create(:name => director_name)
      @director_role ||= Role.first(:name => 'Director') || Role.create(:name => 'Director')
      person.roles << @director_role
      raise SaveException(person, "Unable to save person in add_directors") unless person.save
      self.people << person
    end
  end

  def add_actor(name, character_name)
    Merb.logger.info { "****** add_actor(#{name}, #{character_name})" }
    person = Person.first(:name => name) || Person.create(:name => name)

    character = Character.first(:name => character_name) || Character.create(:name => character_name)
    person.characters << character

    @actor_role ||= Role.first(:name => 'Actor') || Role.create(:name => 'Actor')
    person.roles << @actor_role
    raise SaveException(person, "Unable to save person in add_actor") unless person.save

    self.characters << character
    self.people << person
  end

