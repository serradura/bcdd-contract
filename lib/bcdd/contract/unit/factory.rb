# frozen_string_literal: true

module BCDD::Contract
  class Unit::Factory
    include ::Singleton

    attr_reader :cache

    private :cache

    def initialize
      @cache = {}
    end

    def build(arg)
      return arg if arg.is_a?(Core::Checker)

      return read_cache(arg) if arg.is_a?(::Symbol)

      arg.is_a?(::Proc) ? unit(arg) : type(arg)
    end

    def cached(name, arg)
      name.is_a?(::Symbol) or raise ::ArgumentError, 'must be a symbol'

      checker = build(arg)

      cache[name] = checker

      checker
    end

    def read_cache(name)
      cache[name] or raise ::ArgumentError, format('unknown unit checker %p', name)
    end

    ArityOneHandler =
      ->(strategy) do
        ->(value, err) do
          outcome = strategy.call(value)

          err << outcome if outcome.is_a?(::String)
        end
      end

    def unit(arg)
      (arg.is_a?(::Proc) && arg.lambda?) or raise ::ArgumentError, 'must be a lambda'

      strategy =
        case arg.arity
        when 1 then ArityOneHandler[arg]
        when 2 then arg
        else raise ::ArgumentError, 'must have two arguments (value, errors)'
        end

      new(strategy)
    end

    def type(arg)
      arg.is_a?(::Module) or raise ::ArgumentError, format('%p must be a class, module or lambda', arg)

      cache_item = cache[arg]

      return cache_item if cache_item

      checker = unit(->(value, err) { err << "%p must be a #{arg.name}" unless value.is_a?(arg) })

      cache[arg] = checker
    end

    def new(strategy)
      Core::Factory.new(Unit::Checker, Unit::Checking, strategy)
    end
  end
end
