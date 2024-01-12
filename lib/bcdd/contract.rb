# frozen_string_literal: true

require_relative 'contract/version'
require_relative 'contract/config'
require_relative 'contract/unit'
require_relative 'contract/core/proxy'
require_relative 'contract/proxy'

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
end
