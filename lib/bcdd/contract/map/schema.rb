# frozen_string_literal: true

module BCDD::Contract
  module Map::Schema
    class Checking
      include Core::Checking

      def initialize(schema, value)
        @value = value
        @errors = {}

        validate(schema, @errors)
      end

      ErrorsMsg = ->(errors) do
        messages = errors.map { |key, val| %(#{key}: #{val.is_a?(::Hash) ? ErrorsMsg[val] : val.join(', ')}) }

        "(#{messages.join('; ')})"
      end

      def errors_message
        valid? ? '' : ErrorsMsg[errors]
      end

      private

      def validate(schema, errors)
        errors[value.inspect] = ['must be a Hash'] and return unless value.is_a?(::Hash)

        schema.each do |skey, svalue|
          vvalue = value[skey]

          vchecking = svalue[vvalue]

          errors[skey] = vchecking.errors and next if vchecking.invalid?

          errors[skey] = ['must be a Hash'] and next if svalue.is_a?(Map::Schema::Checker) && !vvalue.is_a?(::Hash)
        end
      end
    end

    module Checker
      include Core::Checker
    end

    def self.new(strategy)
      Core::Factory.new(Checker, Checking, strategy)
    end
  end
end
