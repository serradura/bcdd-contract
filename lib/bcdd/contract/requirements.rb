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
        name.is_a?(Symbol) || Error['%p must be a Symbol', name]
        guard.is_a?(Proc) || Error['%p must be a Proc', guard]

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
        "(#{name} #{expectation.inspect})"
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

    class Checking
      attr_reader :violations, :value

      def initialize(value, requirements)
        @value = value

        @violations = requirements.call(value, violations: {}).freeze
      end

      def to_h
        { value: value, violations: violations }
      end
    end

    class Checker
      attr_reader :requirements

      protected :requirements

      def initialize(requirements)
        @requirements = requirements
      end

      def |(other)
        compose(other, with: Union)
      end

      def &(other)
        compose(other, with: Intersection)
      end

      def clauses
        requirements.composition
      end

      def clause?(name, expectation = UNDEFINED)
        has_key = clauses.key?(name)

        expectation == UNDEFINED ? has_key : has_key && clauses[name].include?(expectation)
      end

      def new(value)
        Checking.new(value, requirements)
      end

      alias [] new

      def inspect
        requirements.inspect
      end

      private

      def compose(other, with:)
        new_requirements = with.new(requirements, other.requirements)

        self.class.new(new_requirements)
      end
    end

    module Factory
      class Registry
        include ::Singleton

        attr_reader :store, :reserved

        def initialize
          @store = {}
          @reserved = ::Set.new
        end

        def self.write(name, factory, reserved:, force:)
          reserved_names = instance.reserved

          reserved_names.include?(name) and raise ::ArgumentError, "#{name} is a reserved name"

          factory_store = instance.store

          !force && factory_store.key?(name) and raise ::ArgumentError, "#{name} already registered"

          reserved_names << name if reserved

          factory_store[name] = factory
        end

        def self.read(name)
          factory_store = instance.store

          factory_store.key?(name) or raise(::ArgumentError, format('%p not registered', name))

          factory_store[name]
        end
      end

      Singleton = ->(name, guard, expectation = nil) do
        clause = Clause.new(name: name, guard: guard, expectation: expectation)

        Checker.new(Requirements::Singleton.new(clause))
      end

      class Instance
        attr_reader :name, :guard, :expectation

        def initialize(name, guard, expectation)
          @name = name
          @guard = guard
          @expectation = expectation

          freeze
        end

        def call(expectation)
          self.expectation&.call(expectation, Error)

          Singleton.call(name, guard, expectation)
        end
      end

      def self.register(name:, guard:, expectation: nil, reserved: false, force: false)
        factory = Instance.new(name, guard, expectation)

        Registry.write(name, factory, reserved: reserved, force: force)
      end

      def self.call(name, value)
        Registry.read(name).call(value)
      end

      def self.type(value)
        call(:type, value)
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def self.with(options)
        type = options.delete(:type)&.then { _1.is_a?(::Array) ? _1.map { |t| type(t) }.reduce(:|) : type(_1) }

        allow_nil = options.delete(:allow_nil)&.then { call(:allow_nil, _1) unless _1.nil? }

        other = options.map do |name, val|
          case val
          when ::Hash then Singleton[name, val.fetch(:guard), val[:expectation]]
          when ::Proc then Singleton[name, val]
          else call(name, val)
          end
        end

        checker = type
        checker = (checker ? ([checker] + other) : other).reduce(:&) unless other.empty?
        checker = checker ? checker | allow_nil : allow_nil if allow_nil
        checker
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    end
  end

  Requirements::Factory.register(
    name: :type,
    guard: ->(value, class_or_mod) { value.is_a?(class_or_mod) },
    expectation: ->(arg, err) { arg.is_a?(::Module) or err['%p must be a Class or a Module', arg] },
    reserved: true
  )

  Requirements::Factory.register(
    name: :format,
    guard: ->(value, regexp) { regexp.match?(value) },
    expectation: ->(arg, err) { arg.is_a?(::Regexp) or err['%p must be a Regexp', arg] },
    reserved: true
  )

  Requirements::Factory.register(
    name: :allow_nil,
    guard: ->(value, bool) { value.nil? == bool },
    expectation: ->(arg, err) { arg == true || arg == false or err['%p must be a boolean', arg] },
    reserved: true
  )

  def self.with(**options)
    Requirements::Factory.with(options)
  end
end
