# frozen_string_literal: true

require 'set'
require 'singleton'

require_relative 'contract/version'
require_relative 'contract/core'
require_relative 'contract/registry'
require_relative 'contract/config'
require_relative 'contract/unit'
require_relative 'contract/proxy'
require_relative 'contract/interface'
require_relative 'contract/assertions'
require_relative 'contract/map'
require_relative 'contract/list'
require_relative 'contract/requirements'

module BCDD
  module Contract
    UNDEFINED = ::Object.new.freeze

    class Error < StandardError
      def self.[](msg, arg_to_print = UNDEFINED)
        message = arg_to_print == UNDEFINED ? msg : format(msg, arg_to_print)

        raise new(message)
      end
    end

    def self.config
      Config.instance
    end

    def self.configuration
      yield(config)

      config.freeze
    end

    def self.proxy(always_enabled: false, &block)
      proxy_class = always_enabled ? Proxy::AlwaysEnabled : Proxy

      ::Class.new(proxy_class, &block)
    end

    def self.error!(message)
      Error[message]
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

    def self.new(arg)
      return arg if arg.is_a?(Core::Checker)

      return schema(arg) if arg.is_a?(::Hash)

      return Registry.fetch(arg) if arg.is_a?(::Symbol)

      return unit(arg) unless arg.is_a?(::Array) || arg.is_a?(::Set)

      list = arg.to_a.flatten

      return list(list[0]) if list.size == 1

      raise ::ArgumentError, 'must be one contract checker'
    end

    singleton_class.send(:alias_method, :[], :new)

    def self.to_proc
      ->(arg) { self[arg] }
    end

    def self.register(**kargs)
      kargs.empty? and raise ::ArgumentError, 'must be passed as keyword arguments'

      kargs.each_with_object({}) do |(key, val), memo|
        memo[key] = Registry.write(key, new(val))
      end
    end

    def self.unit(arg)
      Unit.new(arg)
    end

    def self.list(arg)
      List.new(new(arg))
    end

    def self.schema(arg)
      arg.is_a?(::Hash) or raise ::ArgumentError, 'must be a Hash'

      Map::Schema.new(arg.transform_values { |svalue| new(svalue) })
    end

    def self.pairs(arg)
      arg.is_a?(::Hash) or raise ::ArgumentError, 'must be a Hash'
      arg.keys.size == 1 or raise ::ArgumentError, 'must have only one key and value'

      key, val = arg.to_a.flatten(1)

      Map::Pairs.new(new(key) => new(val))
    end
  end

  def self.Contract(arg)
    Contract.new(arg)
  end
end
