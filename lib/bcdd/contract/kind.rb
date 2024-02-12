# frozen_string_literal: true

module BCDD::Contract
  module Kind
    module Clause
      class Definition
        attr_reader :name, :check, :condition

        FreezeCondition = ->(cond) do
          return cond if cond.is_a?(::Module) || cond.frozen?

          cond.freeze
        end

        def initialize(name:, check:, condition:)
          name.is_a?(Symbol) || BCDD::Contract.error!('name must be a Symbol')
          check.is_a?(Proc) || BCDD::Contract.error!('check must be a Proc')

          @name = name
          @check = check
          @condition = condition.nil? ? true : FreezeCondition[condition]

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

      class Singleton
        attr_reader :definition, :clauses

        private :definition

        def initialize(definition)
          @definition = definition
          @clauses = [definition].freeze
        end

        def call(value, violations:)
          definition.call(value, violations: violations)
        end
      end

      class Intersection
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

      class Union
        attr_reader :clause1, :clause2, :clauses

        private :clause1, :clause2

        def initialize(clause1, clause2)
          @clause1 = clause1
          @clause2 = clause2
          @clauses = [clause1, clause2].freeze
        end

        def call(value, violations:)
          violations1 = clause1.call(value, violations: {})

          return violations if violations1.empty?

          violations2 = clause2.call(value, violations: {})

          return violations if violations2.empty?

          violations2.each do |name, conditions|
            violations1[name] = violations1.key?(name) ? (violations1[name] + conditions).uniq : conditions
          end

          violations.merge!(violations1)
        end
      end
    end

    class Unit
      class << self
        attr_accessor :clauses

        private :clauses=

        alias [] new

        def &(other)
          other < Kind::Unit or BCDD::Contract.error!("argument must be a #{Kind::Unit}, but got #{other}")

          klass = ::Class.new(Kind::Unit)
          klass.send(:clauses=, Clause::Intersection.new([clauses, other.clauses]))
          klass
        end

        def |(other)
          other < Kind::Unit or BCDD::Contract.error!("argument must be a #{Kind::Unit}, but got #{other}")

          klass = ::Class.new(Kind::Unit)
          klass.send(:clauses=, Clause::Union.new(clauses, other.clauses))
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
    clause = Kind::Clause::Definition.new(name: name, check: check, condition: condition)

    klass = ::Class.new(Kind::Unit)
    klass.send(:clauses=, Kind::Clause::Singleton.new(clause))
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
