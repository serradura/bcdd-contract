# frozen_string_literal: true

module BCDD::Contract::Unit
  class Factory
    include ::Singleton

    attr_reader :cache

    private :cache

    def initialize
      @cache = {}
    end

    def call(arg)
      return arg if arg.is_a?(Checker)

      arg.is_a?(::Proc) ? unit(arg) : type(arg)
    end

    def unit(arg)
      (arg.is_a?(::Proc) && arg.lambda?) or raise ::ArgumentError, 'must be a lambda'

      arg.arity == 2 or raise ::ArgumentError, 'must have two arguments (value, errors)'

      ::Module.new.extend(Checker).send(:setup, arg)
    end

    def type(arg)
      arg.is_a?(::Module) or raise ::ArgumentError, format('%p must be a class or a module', arg)

      cache_item = cache[arg]

      return cache_item if cache_item

      checker = unit(->(value, err) { err << "%p must be a #{arg.name}" unless value.is_a?(arg) })

      cache[arg] = checker
    end
  end
end
