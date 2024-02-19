# frozen_string_literal: true

module BCDD::Contract
  require_relative 'undefined'
  require_relative 'error'
  require_relative 'cache'
  require_relative 'value'
  require_relative 'data'

  Value::Factory.register(
    name: :type,
    guard: ->(value, class_or_mod) { value.is_a?(class_or_mod) },
    expectation: ->(arg, err) { arg.is_a?(::Module) or err['%p must be a Class or a Module', arg] },
    reserve: true
  )

  Value::Factory.register(
    name: :format,
    guard: ->(value, regexp) { regexp.match?(value) },
    expectation: ->(arg, err) { arg.is_a?(::Regexp) or err['%p must be a Regexp', arg] },
    reserve: true
  )

  must_be_boolean = ->(arg, err) { arg == true || arg == false or err['%p must be a boolean', arg] }

  Value::Factory.register(
    name: :allow_nil,
    guard: ->(value, bool) { value.nil? == bool },
    expectation: must_be_boolean,
    reserve: true
  )

  Value::Factory.register(
    name: :allow_empty,
    guard: ->(value, bool) { value.respond_to?(:empty?) && value.empty? == bool },
    expectation: must_be_boolean,
    reserve: true
  )

  def self.clause(name, value)
    Value::Factory.clause(name, value)
  end

  def self.with(**options)
    options.key?(:schema) ? Data.with(options) : Value.with(options)
  end
end
