# frozen_string_literal: true

require 'singleton'

require_relative 'contract/version'
require_relative 'contract/config'
require_relative 'contract/unit'
require_relative 'contract/core/proxy'
require_relative 'contract/proxy'
require_relative 'contract/assertions'

module BCDD::Contract
  class Error < StandardError; end

  def self.config
    Config.instance
  end

  def self.configuration
    yield(config)

    config.freeze
  end

  def self.unit(checker)
    Unit.new(checker)
  end

  def self.proxy(always_enabled: false, &block)
    proxy_class = always_enabled ? Proxy::AlwaysEnabled : Proxy

    ::Class.new(proxy_class, &block)
  end

  def self.error!(message)
    raise Error, message
  end

  def self.assert!(value, message, &block)
    return value if (value && !block) || (value && block.call(value))

    error!(format(message, value))
  end

  def self.refute!(value, message, &block)
    return value if (!value && !block) || (value && block && !block.call(value))

    error!(format(message, value))
  end

  def self.assert(value, ...)
    Config.instance.assertions_enabled ? assert!(value, ...) : value
  end

  def self.refute(value, ...)
    Config.instance.assertions_enabled ? refute!(value, ...) : value
  end

  def self.[](arg)
    Unit[arg]
  end
end
