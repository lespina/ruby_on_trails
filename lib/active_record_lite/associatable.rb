require_relative 'searchable'
require 'active_support/inflector'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    default = {
      foreign_key: "#{name}_id".to_sym,
      class_name: "#{name.to_s.camelcase}",
      primary_key: :id
    }

    options = default.merge(options)

    self.foreign_key = options[:foreign_key]
    self.class_name = options[:class_name]
    self.primary_key = options[:primary_key]
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    default = {
      foreign_key: "#{self_class_name.underscore}_id".to_sym,
      class_name: "#{name.to_s.singularize.camelcase}",
      primary_key: :id
    }

    options = default.merge(options)

    self.foreign_key = options[:foreign_key]
    self.class_name = options[:class_name]
    self.primary_key = options[:primary_key]
  end
end

module Associatable
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options

    define_method(name) do
      foreign_key_id = self.send(options.foreign_key)
      result = options.model_class.where(id: foreign_key_id)
      result.first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)

    define_method(name) do
      options.model_class.where(options.foreign_key => self.id)
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options =
        through_options.model_class.assoc_options[source_name]

      foreign_key_id = self.send(through_options.foreign_key)
      result = through_options.model_class.where(id: foreign_key_id)
      sub_result = result.first

      foreign_key_id = sub_result.send(source_options.foreign_key)
      result = source_options.model_class.where(id: foreign_key_id)
      result.first
    end
  end
end

class SQLObject
  extend Associatable
end
