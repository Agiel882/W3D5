require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    @class_name.constantize.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
      @foreign_key = options[:foreign_key] || (name.to_s + "_id").to_sym
      @primary_key = options[:primary_key] || :id
      @class_name = options[:class_name] || name.to_s.camelize
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key] || (self_class_name.underscore + "_id").to_sym
    @primary_key = options[:primary_key] || :id
    @class_name = options[:class_name] || name.to_s.classify
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options
    define_method(name) do
      value = send(options.foreign_key)
      return nil unless value
      data = DBConnection.execute(<<~SQL)
        SELECT
          * 
        FROM
          #{options.table_name}
        WHERE
          #{options.primary_key} = #{value}
      SQL
      options.model_class.parse_all(data).first
    end 
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
    define_method(name) do
      foreign_key = options.foreign_key
      primary_key = self.send(options.primary_key)
      data = options.model_class.where(foreign_key => primary_key)  
    end
  end

  def assoc_options
    @options ||= {}
  end
end


class SQLObject
  extend Associatable
end
