# frozen_string_literal: true

module BCDD::Contract
  module Unit::Factory
    def self.new(strategy)
      Core::Factory.new(Unit::Checker, Unit::Checking, strategy)
    end

    def self.build(arg)
      return arg if arg.is_a?(Core::Checker)

      return Registry.unit(arg) if arg.is_a?(::Symbol)

      return type!(::NilClass) if arg.nil?

      arg.is_a?(::Proc) ? lambda!(arg) : type!(arg)
    end

    ArityOneHandler =
      ->(strategy) do
        ->(value, err) do
          outcome = strategy.call(value)

          err << outcome if outcome.is_a?(::String)
        end
      end

    def self.lambda!(arg)
      (arg.is_a?(::Proc) && arg.lambda?) or raise ::ArgumentError, 'must be a lambda'

      strategy =
        case arg.arity
        when 1 then ArityOneHandler[arg]
        when 2 then arg
        else raise ::ArgumentError, 'must have two arguments (value, errors)'
        end

      new(strategy)
    end

    def self.type!(arg)
      arg.is_a?(::Module) or raise ::ArgumentError, format('%p must be a class, module or lambda', arg)

      cache_item = Registry.unit(arg)

      return cache_item if cache_item

      checker = lambda!(->(value, err) { err << "%p must be a #{arg.name}" unless value.is_a?(arg) })

      Registry.write(arg, checker)
    end
  end
end
