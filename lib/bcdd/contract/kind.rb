# frozen_string_literal: true

module BCDD::Contract
  module Kind
    class Clause
      attr_reader :name, :check, :condition

      def initialize(name:, check:, condition:)
        name.is_a?(Symbol) || BCDD::Contract.error!('name must be a Symbol')
        check.is_a?(Proc) || BCDD::Contract.error!('check must be a Proc')

        @name = name
        @check = check
        @condition = (condition || true).freeze

        freeze
      end

      def call(value, violations:)
        violations[name] = [condition] unless check.call(value)

        violations.transform_values!(&:freeze).freeze
      end
    end

    class Unit
      class << self
        attr_accessor :clause

        private :clause=

        alias [] new
      end

      attr_reader :violations, :value

      def initialize(value)
        @value = value

        @violations = self.class.clause.call(value, violations: {})
      end

      def to_h
        { value: value, violations: violations }
      end
    end
  end

  def self.unit!(name:, check:, condition: nil)
    klass = ::Class.new(Kind::Unit)
    klass.send(:clause=, Kind::Clause.new(name: name, check: check, condition: condition))
    klass
  end
end
