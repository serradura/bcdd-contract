# frozen_string_literal: true

module BCDD::Contract
  require_relative 'undefined'
  require_relative 'error'
  require_relative 'cache'
  require_relative 'value'
  require_relative 'data'

  def self.with(**options)
    create = Data::Create.options?(options) ? Data::Create : Value::Create

    create.with(options)
  end

  def self.register!(name, options)
    contract = Data::Create.options?(options) ? Data::Create : Value::Create

    contract.registered(name, options)
  end
end
