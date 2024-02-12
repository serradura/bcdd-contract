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
        violations[name] = [condition] unless valid?(value)

        violations.transform_values!(&:freeze).freeze
      end

      def valid?(value)
        check.arity == 2 ? check.call(value, condition) : check.call(value)
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

  TYPE_CHECK = ->(value, class_or_mod) { value.is_a?(class_or_mod) }

  def self.type!(class_or_module)
    class_or_module.is_a?(Module) or BCDD::Contract.error!('argument must be a Class or a Module')

    unit!(name: :type, check: TYPE_CHECK, condition: class_or_module)
  end
end
