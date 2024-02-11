# frozen_string_literal: true

module BCDD::Contract
  module List
    class Checking
      include Core::Checking

      def initialize(checker, value)
        @value = value
        @errors = []

        validate(checker, @errors)
      end

      def errors_message
        valid? ? '' : "(#{errors.join('; ')})"
      end

      private

      def validate(checker, errors)
        errors << "#{value.inspect} must be a Set | Array" and return unless value.is_a?(::Set) || value.is_a?(::Array)
        errors << 'is empty' and return if value.empty?

        value.each_with_index do |vval, index|
          val_checking = checker[vval]

          errors << "#{index}: #{val_checking.errors_message}" if val_checking.invalid?
        end
      end
    end

    module Checker
      include Core::Checker
    end

    def self.new(strategy)
      return strategy if strategy.is_a?(Checker)

      Core::Factory.new(Checker, Checking, strategy)
    end
  end

  private_constant :List
end
