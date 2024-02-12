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
        @condition = condition.nil? ? true : condition

        freeze
      end

      def call(value, violations:)
        violations[name] = [condition] unless valid?(value)

        violations
      end

      private

      def valid?(value)
        check.arity == 2 ? check.call(value, condition) : check.call(value)
      end
    end

    class Clauses
      attr_reader :clauses

      def initialize(clauses)
        clauses.is_a?(Array) || BCDD::Contract.error!('clauses must be an Array')

        @clauses = clauses
      end

      def call(value, violations:)
        clauses.each do |clause|
          break unless violations.empty?

          clause.call(value, violations: violations)
        end

        violations
      end
    end

    class Unit
      class << self
        attr_accessor :clauses

        private :clauses=

        alias [] new

        def &(other)
          clauses = Clauses.new(self.clauses.clauses + other.clauses.clauses)

          klass = ::Class.new(Kind::Unit)
          klass.send(:clauses=, clauses)
          klass
        end
      end

      attr_reader :violations, :value

      def initialize(value)
        @value = value

        @violations = self.class.clauses.call(value, violations: {}).freeze
      end

      def to_h
        { value: value, violations: violations }
      end
    end
  end

  def self.unit!(name:, check:, condition: nil)
    clause = Kind::Clause.new(name: name, check: check, condition: condition)

    klass = ::Class.new(Kind::Unit)
    klass.send(:clauses=, Kind::Clauses.new([clause]))
    klass
  end

  TYPE_CHECK = ->(value, class_or_mod) { value.is_a?(class_or_mod) }

  def self.type!(class_or_module)
    class_or_module.is_a?(Module) or BCDD::Contract.error!('argument must be a Class or a Module')

    unit!(name: :type, check: TYPE_CHECK, condition: class_or_module)
  end

  FORMAT_CHECK = ->(value, format) { format.match?(value) }

  def self.format!(format)
    format.is_a?(Regexp) or BCDD::Contract.error!('format must be a Regexp')

    unit!(name: :format, check: FORMAT_CHECK, condition: format)
  end

  Nil = unit!(name: :nil, check: ->(value) { value.nil? }, condition: true)
  NotNil = unit!(name: :nil, check: ->(value) { !value.nil? }, condition: false)

  def self.nil!
    Nil
  end

  def self.not_nil!
    NotNil
  end
end
