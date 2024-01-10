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

        @errors.map! { |error| format(error, value) }.freeze
      end

      def errors_message
        errors.join(', ')
      end

      def +@
        return value if valid?

        raise Error, errors_message
      end

      alias !@ +@
      alias value_or_err! +@
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

      private

      attr_reader :checker

      def setup(checker)
        @checker = checker
      end
    end

    def self.new(checker)
      (checker.is_a?(::Proc) && checker.lambda?) or raise ::ArgumentError, 'must be a lambda'
      checker.arity == 2 or raise ::ArgumentError, 'must have two arguments (value, errors)'

      mod = ::Module.new.extend(Checker)
      mod.send(:setup, checker)
      mod
    end

    def self.[](class_or_mod)
      class_or_mod.is_a?(::Module) or raise ::ArgumentError, format('%p must be a class or a module', class_or_mod)

      new(->(value, err) { err << "%p must be a #{class_or_mod.name}" unless value.is_a?(class_or_mod) })
    end
  end
end
