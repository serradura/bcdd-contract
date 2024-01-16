# frozen_string_literal: true

module BCDD::Contract
  module Map::Pairs
    class Checking
      include Core::Checking

      def initialize(schema, value)
        @value = value
        @errors = []

        validate(schema.to_a.flatten(1), @errors)
      end

      def errors_message
        valid? ? '' : errors.map { |msg| "(#{msg})" }.join('; ')
      end

      private

      def validate(schema_key_and_value, errors)
        skey, sval = schema_key_and_value

        errors << "#{value.inspect} must be a Hash" and return unless value.is_a?(::Hash)
        errors << 'is empty' and return if value.empty?

        value.each do |vkey, vval|
          key_checking = skey[vkey]

          errors << "key: #{key_checking.errors_message}" and next if key_checking.invalid?

          val_checking = sval[vval]

          errors << "#{vkey}: #{val_checking.errors_message}" and next if val_checking.invalid?
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
