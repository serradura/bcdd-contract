# frozen_string_literal: true

module BCDD::Contract
  module Clause
    class Definition
      attr_reader :name, :check, :condition

      FreezeCondition = ->(cond) do
        return cond if cond.is_a?(::Module) || cond.frozen?

        cond.freeze
      end

      def initialize(name:, check:, condition:)
        name.is_a?(Symbol) || Error['name must be a Symbol']
        check.is_a?(Proc) || Error['check must be a Proc']

        @name = name
        @check = check
        @condition = condition.nil? ? true : FreezeCondition[condition]

        freeze
      end

      def call(value, violations:)
        violations[name] = [condition] unless valid?(value)

        violations
      end

      def inspect
        "#{name}(#{condition.inspect})"
      end

      private

      def valid?(value)
        check.arity == 2 ? check.call(value, condition) : check.call(value)
      end
    end

    module Expectation
      def clauses
        @clauses ||= flat_options.each_with_object(Hash.new { |h, k| h[k] = [] }) do |clause, hash|
          hash[clause.name] << clause.condition
        end
      end

      protected

      def flat_options
        options.flat_map { _1.is_a?(Expectation) ? _1.flat_options : _1 }
      end
    end

    class Singleton
      include Expectation

      attr_reader :definition, :options

      private :definition

      def initialize(definition)
        @options = [definition].freeze
        @definition = definition
      end

      def call(value, violations:)
        definition.call(value, violations: violations)
      end

      def inspect
        definition.inspect
      end
    end

    class Intersection
      include Expectation

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
      include Expectation

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

        violations2.each do |name, conditions|
          violations1[name] = violations1.key?(name) ? (violations1[name] + conditions).uniq : conditions
        end

        violations.merge!(violations1)
      end

      def inspect
        "(#{clause1.inspect} | #{clause2.inspect})"
      end
    end
  end

  module Kind
    class Object
      class << self
        attr_accessor :definition

        private :definition=

        alias [] new

        def &(other)
          other < Kind::Object or Error["argument must be a #{Kind::Object}, but got #{other}"]

          klass = ::Class.new(Kind::Object)
          klass.send(:definition=, Clause::Intersection.new([definition, other.definition]))
          klass
        end

        def |(other)
          other < Kind::Object or Error["argument must be a #{Kind::Object}, but got #{other}"]

          klass = ::Class.new(Kind::Object)
          klass.send(:definition=, Clause::Union.new(definition, other.definition))
          klass
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
  end

  def self.unit!(name:, check:, condition: nil)
    clause = Clause::Definition.new(name: name, check: check, condition: condition)

    klass = ::Class.new(Kind::Object)
    klass.send(:definition=, Clause::Singleton.new(clause))
    klass
  end

  TYPE_CHECK = ->(value, class_or_mod) { value.is_a?(class_or_mod) }

  def self.type!(class_or_module)
    class_or_module.is_a?(Module) or Error['argument must be a Class or a Module']

    unit!(name: :type, check: TYPE_CHECK, condition: class_or_module)
  end

  FORMAT_CHECK = ->(value, format) { format.match?(value) }

  def self.format!(format)
    format.is_a?(Regexp) or Error['format must be a Regexp']

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
