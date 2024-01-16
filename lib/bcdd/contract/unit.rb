# frozen_string_literal: true

module BCDD::Contract
  # A module that can be used to create contract checkers
  # (a module that can be used to perform validations and type checkings).
  #
  # @example
  # cannot_be_inf = ->(val, err) { err << '%p cannot be infinite' if val.respond_to?(:infinite?) && val.infinite? }
  # cannot_be_nan = ->(val, err) { err << '%p cannot be nan' if val.respond_to?(:nan?) && val.nan? }
  #
  # CannotBeInfinity = ::BCDD::Contract::Unit.new(cannot_be_inf)
  # CannotBeNaN      = ::BCDD::Contract::Unit.new(cannot_be_nan)
  # IsNumeric        = ::BCDD::Contract::Unit.new(Numeric)
  #
  # ValidNumber = IsNumeric & CannotBeNaN & CannotBeInfinity
  module Unit
    class Checking
      include Core::Checking

      def initialize(strategy, value)
        @value = value

        errors = [].tap { |err| strategy.call(value, err) }

        @errors = errors.flat_map { |error| format(error, value) }
      end

      def errors_message
        errors.join(', ')
      end
    end

    module Checker
      include Core::Checker

      SequenceMapper = ->(strategy1, strategy2) do
        ->(value, err) do
          strategy1.call(value, err)

          return unless err.empty?

          strategy2.call(value, err)
        end
      end

      def &(other)
        other = Factory.instance.build(other)

        check_in_sequence = SequenceMapper.call(strategy, other.strategy)

        Factory.instance.new(check_in_sequence)
      end

      ParallelMapper = ->(strategy1, strategy2) do
        ->(value, err) do
          err1 = []
          err2 = []

          strategy1.call(value, err1)
          strategy2.call(value, err2)

          return if err1.empty? || err2.empty?

          err << err1.concat(err2).map { |msg| format(msg, value) }.join(' OR ')
        end
      end

      def |(other)
        other = Factory.instance.build(other)

        check_in_parallel = ParallelMapper.call(strategy, other.strategy)

        Factory.instance.new(check_in_parallel)
      end
    end

    class Factory
      include ::Singleton

      attr_reader :cache

      private :cache

      def initialize
        @cache = {}
      end

      def build(arg)
        return arg if arg.is_a?(Checker)

        arg.is_a?(::Proc) ? unit(arg) : type(arg)
      end

      def unit(arg)
        (arg.is_a?(::Proc) && arg.lambda?) or raise ::ArgumentError, 'must be a lambda'

        arg.arity == 2 or raise ::ArgumentError, 'must have two arguments (value, errors)'

        new(arg)
      end

      def type(arg)
        arg.is_a?(::Module) or raise ::ArgumentError, format('%p must be a class, module or lambda', arg)

        cache_item = cache[arg]

        return cache_item if cache_item

        checker = unit(->(value, err) { err << "%p must be a #{arg.name}" unless value.is_a?(arg) })

        cache[arg] = checker
      end

      def new(strategy)
        Core::Factory.new(Checker, Checking, strategy)
      end
    end

    def self.new(arg)
      Factory.instance.build(arg)
    end
  end

  private_constant :Unit
end
