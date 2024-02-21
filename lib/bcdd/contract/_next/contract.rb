# frozen_string_literal: true

module BCDD::Contract
  require_relative 'undefined'
  require_relative 'error'
  require_relative 'cache'
  require_relative 'value'
  require_relative 'data'

  def self.with(**options)
    options.key?(:schema) ? Data.with(options) : Value::Create.with(options)
  end

  def self.register!(name, options)
    Value::Create.registered(name, options)
  end
end
