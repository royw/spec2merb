class SpecParser
  attr_reader :descriptions, :properties, :relationships, :requirements, :routes, :synopses
  
  def initialize
    @descriptions = []
    @properties = {}
    @relationships = []
    @requirements = {}
    @routes = {}
    @synopses = {}
  end
  
  def parse(spec)
    eval spec
  end
  
  # capture the describe info from the rspec
  def describe(str,&blk)
    unless str.nil?
      if str =~ /^\s*(\S+)\s+Model\s*$/
        @descriptions << $1
        @routes[$1] ||= []
      end
    end
    blk.call unless blk.nil?
  end

  # capture the it info from the rspec
  def it(str,&blk)
    description = @descriptions.last
    through_singular = nil
    through_plural = nil
    if str =~ /\[.*\svia\s(\S+)\s*\]/
      through_singular = $1.snake_case
      through_plural = through_singular.pluralize
    end
    case str
    when /^should have a relationship.*\s(\S+)\s+\((.*)\)\s*\[has\s+(\S+)\s+(\S+)[^\]]*\]/
      @relationships << {
        :filename => description,
        :variable => $1,
        :comment => $2,
        :has_relationship => $3,
        :model => $4,
        :through => through_plural
      }
      @routes[description] << $1
    when /should have a relationship.*\s(\S+)\s*\[has\s+(\S+)\s+(\S+)[^\]]*\]/
      @relationships << {
        :filename => description,
        :variable => $1,
        :comment => '',
        :has_relationship => $2,
        :model => $3,
        :through => through_plural
      }
      @routes[description] << $1
    when /^should declare a list.*\s(\S+)\s+\((.*)\)\s*\[list[^\]]*\]/
      @relationships << {
        :filename => description,
        :variable => $1,
        :comment => $2,
        :relationship => "is :list, :scope => [:#{$1}_id]",
        :through => through_plural
      }
    when /^should declare a list.*\s(\S+)\s*\[list[^\]]*\]/
      @relationships << {
        :filename => description,
        :variable => $1,
        :comment => '',
        :relationship => "is :list, :scope => [:#{$1}_id]",
        :through => through_plural
      }
    when /^should reference.*\s(\S+)\s+\((.*)\)\s*\[belongs_to\s+(\S+)[^\]]*\]/
      @relationships << {
        :filename => description,
        :variable => $1,
        :comment => $2,
        :relationship => "belongs_to :#{$1}",
        :model => $3
      }
      @routes[description] << $1
    when /^should reference.*\s(\S+)\s*\[belongs_to\s+(\S+)[^\]]*\]/
      @relationships << {
        :filename => description,
        :variable => $1,
        :comment => '',
        :relationship => "belongs_to :#{$1}",
        :model => $2
      }
      @routes[description] << $1
    when /should have.*\s(\S+)\s*\((.*?)\)\s*\[(\S+)[^\]]*\]/
      @properties[description] ||= []
      # @properties[description] << ""#{$1}:#{$3}"
      @properties[description] << {
        :variable => $1,
        :comment => $2,
        :type => $3
      }
    when /should have.*\s(\S+)\s*\[(\S+)[^\]]*\]/
      @properties[description] ||= []
      # @properties[description] << "#{$1}:#{$2}"
      @properties[description] << {
        :variable => $1,
        :comment => '',
        :type => $2
      }
    else
      @requirements[description] ||= []
      @requirements[description] << str
    end
  end

  # capture the synopsis info from the rspec
  def synopsis(*args)
    description = @descriptions.last
    @synopses[description] = args
  end

end