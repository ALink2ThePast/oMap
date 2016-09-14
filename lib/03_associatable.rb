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
    self.class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    defaults = {
      foreign_key: "#{name}_id".to_sym,
      class_name: name.to_s.camelcase,
      primary_key: :id
    }

    defaults.each do |col,_|
      self.send("#{col}=", options[col].nil? ? defaults[col] : options[col])
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {
      foreign_key: "#{self_class_name.underscore}_id".to_sym,
      class_name: name.to_s.singularize.camelcase,
      primary_key: :id
    }

    defaults.each do |col,_|
      self.send("#{col}=", options[col].nil? ? defaults[col] : options[col])
    end
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)

    define_method(name) do
      belongs_options = self.class.assoc_options[name]
      foreign_key_val = self.send(belongs_options.foreign_key)

      target_class = belongs_options.model_class
      target_class.where(belongs_options.primary_key => foreign_key_val).first
    end

  end

  def has_many(name, options = {})
    self.assoc_options[name] = HasManyOptions.new(name, self.to_s, options)

    define_method(name) do
      has_many_options = self.class.assoc_options[name]
      key_val = self.send(has_many_options.primary_key)
      has_many_options.model_class
        .where(has_many_options.foreign_key => key_val)
    end
  end

  def assoc_options
    @assoc_options ||= {}
    @assoc_options
  end
end

class SQLObject
  extend Associatable
end
