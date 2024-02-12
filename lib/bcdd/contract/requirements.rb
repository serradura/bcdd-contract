# frozen_string_literal: true

module BCDD::Contract
  class Requirements
    class Clause
      attr_reader :name, :guard, :expectation

      FreezeCondition = ->(cond) do
        return cond if cond.is_a?(::Module) || cond.frozen?

        cond.freeze
      end

      def initialize(name:, guard:, expectation:)
        name.is_a?(Symbol) || Error['name must be a Symbol']
        guard.is_a?(Proc) || Error['guard must be a Proc']

        @name = name
        @guard = guard
        @expectation = expectation.nil? ? true : FreezeCondition[expectation]

        freeze
      end

      def call(value, violations:)
        violations[name] = [expectation] unless valid?(value)

        violations
      end

      def inspect
        "#{name}(#{expectation.inspect})"
      end

      private

      def valid?(value)
        guard.arity == 2 ? guard.call(value, expectation) : guard.call(value)
      end
    end

    module Composition
      def composition
        @composition ||= begin
          expectations_by_name = Hash.new { |h, k| h[k] = [] }

          clauses!
            .each_with_object(expectations_by_name) { |clause, hash| hash[clause.name] << clause.expectation }
            .transform_values { _1.uniq.freeze }
            .freeze
        end
      end

      def clauses!
        clauses.flat_map { _1.is_a?(Composition) ? _1.clauses! : _1 }
      end

      def clauses
        Error['must be implemented']
      end
    end

    class Singleton
      include Composition

      attr_reader :clause, :clauses

      private :clause

      def initialize(clause)
        @clause = clause
        @clauses = [clause].freeze
      end

      def call(value, violations:)
        clause.call(value, violations: violations)
      end

      def inspect
        clause.inspect
      end
    end

    class Intersection
      include Composition

      attr_reader :clauses

      def initialize(clause1, clause2)
        @clauses = [clause1, clause2].freeze
      end

      def call(value, violations:)
        clauses.each do |clause|
          break unless violations.empty?

          clause.call(value, violations: violations)
        end

        violations
      end

      def inspect
        "(#{clauses.map(&:inspect).join(' & ')})"
      end
    end

    class Union
      include Composition

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

        violations2.each do |name, expectations|
          violations1[name] = violations1.key?(name) ? (violations1[name] + expectations).uniq : expectations
        end

        violations.merge!(violations1)
      end

      def inspect
        "(#{clause1.inspect} | #{clause2.inspect})"
      end
    end

    class Object
      class << self
        attr_accessor :requirements

        private :requirements=

        alias [] new

        def |(other)
          Requirements.composition(self, other, strategy: Union)
        end

        def &(other)
          Requirements.composition(self, other, strategy: Intersection)
        end

        def clauses
          requirements.composition
        end

        def clause?(name)
          clauses.key?(name)
        end

        def clause(name)
          clauses[name]
        end
      end

      attr_reader :violations, :value

      def initialize(value)
        @value = value

        @violations = self.class.requirements.call(value, violations: {}).freeze
      end

      def to_h
        { value: value, violations: violations }
      end
    end

    def self.object(clauses)
      klass = ::Class.new(Object)
      klass.send(:requirements=, clauses)
      klass
    end

    def self.singleton(name:, guard:, expectation:)
      clause = Clause.new(name: name, guard: guard, expectation: expectation)

      object(Singleton.new(clause))
    end

    def self.composition(curr, other, strategy:)
      curr < Object or Error["argument must be a #{Object}, but got #{curr}"]
      other < Object or Error["argument must be a #{Object}, but got #{other}"]

      requirements = strategy.new(curr.requirements, other.requirements)

      object(requirements)
    end
  end

  def self.unit!(name:, guard:, expectation: nil)
    Requirements.singleton(name: name, guard: guard, expectation: expectation)
  end

  TYPE_CHECK = ->(value, class_or_mod) { value.is_a?(class_or_mod) }

  def self.type!(class_or_module)
    class_or_module.is_a?(Module) or Error['argument must be a Class or a Module']

    unit!(name: :type, guard: TYPE_CHECK, expectation: class_or_module)
  end

  FORMAT_CHECK = ->(value, format) { format.match?(value) }

  def self.format!(format)
    format.is_a?(Regexp) or Error['format must be a Regexp']

    unit!(name: :format, guard: FORMAT_CHECK, expectation: format)
  end

  Nil = Requirements.singleton(name: :nil, guard: ->(value) { value.nil? }, expectation: true)
  NotNil = Requirements.singleton(name: :nil, guard: ->(value) { !value.nil? }, expectation: false)

  # rubocop:disable Style/OptionalBooleanParameter
  def self.allow_nil!(expectation = true)
    expectation == false ? NotNil : Nil
  end
  # rubocop:enable Style/OptionalBooleanParameter
end
