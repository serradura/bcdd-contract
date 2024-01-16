# frozen_string_literal: true

module BCDD::Contract
  module Core::Checking
    attr_reader :value, :errors

    def initialize(_checker, _value)
      raise Error, 'not implemented'
    end

    def valid?
      errors.empty?
    end

    def invalid?
      !valid?
    end

    alias errors? invalid?

    def errors_message
      raise Error, 'not implemented'
    end

    def raise_validation_errors!
      raise Error, errors_message if invalid?
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
