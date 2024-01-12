# frozen_string_literal: true

module BCDD::Contract
  # A module that can be used to create contract checkers
  # (a module that can be used to perform validations and type checkings).
  #
  # @example
  # Name = ::BCDD::Contract::Unit.new ->(value, err) do
  #   err << '%p must be a string' and return unless value.is_a?(::String)
  #   err << '%p must be a filled string' if value.empty?
  # end
  #
  # ValidNumber = ::BCDD::Contract::Unit.new ->(value, err) do
  #   err << '%p must be numeric' and return unless value.is_a?(::Numeric)
  #   err << '%p cannot be nan' and return if value.respond_to?(:nan?) && value.nan?
  #   err << '%p cannot be infinite' if value.respond_to?(:infinite?) && value.infinite?
  # end
  module Unit
    class Checking
      attr_reader :value

      def initialize(strategy, value)
        @value = value
        @errors = []

        strategy.call(value, @errors)
      end

      def valid?
        @errors.empty?
      end

      def invalid?
        !valid?
      end

      alias errors? invalid?

      def errors
        return @errors if @errors.frozen?

        @errors = @errors.flat_map { |error| format(error, value) }.freeze
      end

      def errors_message
        errors.join(', ')
      end

      def raise_validation_errors!
        raise Error, errors_message if invalid?
      end

      def +@
        raise_validation_errors! || value
      end

      alias !@ +@
      alias value_or_raise_validation_errors! +@
    end

    module Checker
      def [](value)
        Checking.new(checker, value)
      end

      def ===(value)
        self[value].valid?
      end

      def to_proc
        ->(value) { self[value] }
      end

      SequenceMapper = ->(strategies) do
        ->(value, err) { strategies.each { |strategy| strategy.call(value, err) if err.empty? } }
      end

      def &(other)
        other.is_a?(Checker) or raise ::ArgumentError, 'must be a BCDD::Contract::Unit::Checker'

        check_in_sequence = SequenceMapper.call([checker, other.checker])

        ::Module.new.extend(Checker).send(:setup, check_in_sequence)
      end

      def invariant(value)
        self[value].raise_validation_errors!

        output = yield(value)

        self[value].raise_validation_errors!

        output
      end

      protected

      attr_reader :checker

      def setup(checker)
        tap { @checker = checker }
      end

      private_constant :SequenceMapper
    end

    def self.new(checker)
      (checker.is_a?(::Proc) && checker.lambda?) or raise ::ArgumentError, 'must be a lambda'

      checker.arity == 2 or raise ::ArgumentError, 'must have two arguments (value, errors)'

      ::Module.new.extend(Checker).send(:setup, checker)
    end

    def self.[](arg)
      return new(arg) if arg.is_a?(::Proc)

      arg.is_a?(::Module) or raise ::ArgumentError, format('%p must be a class or a module', arg)

      new(->(value, err) { err << "%p must be a #{arg.name}" unless value.is_a?(arg) })
    end
  end
end
