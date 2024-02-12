# frozen_string_literal: true

module BCDD::Contract
  module Provisions
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
        @composition ||= clauses!.each_with_object(Hash.new { |h, k| h[k] = [] }) do |clause, hash|
          hash[clause.name] << clause.expectation
        end
      end

      def clauses!
        options.flat_map { _1.is_a?(Composition) ? _1.clauses! : _1 }
      end
    end

    class Singleton
      include Composition

      attr_reader :clause, :options

      private :clause

      def initialize(clause)
        @clause = clause
        @options = [clause].freeze
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

      attr_reader :options

      def initialize(options)
        options.is_a?(Array) || Error['options must be an Array']

        @options = options
      end

      def call(value, violations:)
        options.each do |clause|
          break unless violations.empty?

          clause.call(value, violations: violations)
        end

        violations
      end

      def inspect
        "(#{options.map(&:inspect).join(' & ')})"
      end
    end

    class Union
      include Composition

      attr_reader :clause1, :clause2, :options

      private :clause1, :clause2

      def initialize(clause1, clause2)
        @clause1 = clause1
        @clause2 = clause2
        @options = [clause1, clause2].freeze
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
        attr_accessor :definition

        private :definition=

        alias [] new

        def &(other)
          Provisions.intersection(self, other)
        end

        def |(other)
          Provisions.union(self, other)
        end
      end

      attr_reader :violations, :value

      def initialize(value)
        @value = value

        @violations = self.class.definition.call(value, violations: {}).freeze
      end

      def to_h
        { value: value, violations: violations }
      end
    end

    extend self

    def singleton(name:, guard:, expectation:)
      clause = Clause.new(name: name, guard: guard, expectation: expectation)

      klass = ::Class.new(Object)
      klass.send(:definition=, Singleton.new(clause))
      klass
    end

    def intersection(current, other)
      current < Object or Error["argument must be a #{Object}, but got #{current}"]
      other < Object or Error["argument must be a #{Object}, but got #{other}"]

      klass = ::Class.new(Object)
      klass.send(:definition=, Intersection.new([current.definition, other.definition]))
      klass
    end

    def union(current, other)
      current < Object or Error["argument must be a #{Object}, but got #{current}"]
      other < Object or Error["argument must be a #{Object}, but got #{other}"]

      klass = ::Class.new(Object)
      klass.send(:definition=, Union.new(current.definition, other.definition))
      klass
    end
  end

  def self.unit!(name:, guard:, expectation: nil)
    Provisions.singleton(name: name, guard: guard, expectation: expectation)
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

  Nil = unit!(name: :nil, guard: ->(value) { value.nil? }, expectation: true)
  NotNil = unit!(name: :nil, guard: ->(value) { !value.nil? }, expectation: false)

  def self.nil!
    Nil
  end

  def self.not_nil!
    NotNil
  end
end
