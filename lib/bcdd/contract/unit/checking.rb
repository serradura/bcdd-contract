# frozen_string_literal: true

module BCDD::Contract::Unit
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
      raise ::BCDD::Contract::Error, errors_message if invalid?
    end

    def value_or_raise_validation_errors!
      raise_validation_errors! || value
    end

    alias !@ value_or_raise_validation_errors!
    alias +@ value_or_raise_validation_errors!
    alias value! value_or_raise_validation_errors!
    alias assert! value_or_raise_validation_errors!
  end
end
