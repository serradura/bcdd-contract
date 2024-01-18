# frozen_string_literal: true

module BCDD::Contract
  # A module that can be used to create contract checkers
  # (a module that can be used to perform validations and type checkings).
  #
  # @example
  # cannot_be_inf = ->(val, err) { err << '%p cannot be infinite' if val.respond_to?(:infinite?) && val.infinite? }
  # cannot_be_nan = ->(val, err) { err << '%p cannot be nan' if val.respond_to?(:nan?) && val.nan? }
  #
  # IsNumeric = ::BCDD::Contract[Numeric] & cannot_be_inf & cannot_be_nan
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

    require_relative 'unit/checker'
    require_relative 'unit/factory'

    def self.new(arg)
      return Factory.instance.build(arg) unless arg.is_a?(::Hash)

      arg.each_with_object({}) { |(name, value), hash| hash[name] = Factory.instance.cached(name, value) }
    end
  end

  private_constant :Unit
end
