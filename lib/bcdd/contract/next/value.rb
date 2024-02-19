# frozen_string_literal: true

module BCDD::Contract
  module Value
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

    class Single
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
        @clauses =
          if !clause1.is_a?(Union) && !clause2.is_a?(Union)
            (clause1.clauses + clause2.clauses).freeze
          else
            [clause1, clause2].freeze
          end
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

      def valid?
        violations.empty?
      end

      def invalid?
        !valid?
      end

      alias violations? invalid?

      def to_h
        { value: value, violations: violations }
      end
    end

    class Checker
      attr_reader :requirements

      protected :requirements

      def self.single(name, guard, expectation = nil)
        clause = Clause.new(name: name, guard: guard, expectation: expectation)

        new(Single.new(clause))
      end

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

      def new(value)
        Checking.new(value, requirements)
      end

      alias [] new

      def ===(value)
        new(value).valid?
      end

      def inspect
        requirements.inspect
      end

      alias to_s inspect

      private

      def compose(other, with:)
        new_requirements = with.new(requirements, other.requirements)

        self.class.new(new_requirements)
      end
    end

    module Factory
      REGISTRY = Cache.new

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

          Checker.single(name, guard, expectation)
        end
      end

      def self.register(name:, guard:, expectation: nil, reserve: false, force: false)
        factory = Instance.new(name, guard, expectation)

        REGISTRY.write(name, factory, reserve: reserve, force: force)
      end

      must_be_boolean = ->(arg, err) { arg == true || arg == false or err['%p must be a boolean', arg] }

      register(
        name: :allow_nil,
        guard: ->(value, bool) { value.nil? == bool },
        expectation: must_be_boolean,
        reserve: true
      )

      register(
        name: :allow_empty,
        guard: ->(value, bool) { value.respond_to?(:empty?) && value.empty? == bool },
        expectation: must_be_boolean,
        reserve: true
      )

      register(
        name: :type,
        guard: ->(value, class_or_mod) { value.is_a?(class_or_mod) },
        expectation: ->(arg, err) { arg.is_a?(::Module) or err['%p must be a Class or a Module', arg] },
        reserve: true
      )

      register(
        name: :format,
        guard: ->(value, regexp) { regexp.match?(value) },
        expectation: ->(arg, err) { arg.is_a?(::Regexp) or err['%p must be a Regexp', arg] },
        reserve: true
      )
    end

    extend self

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def with(options)
      type      = options.delete(:type)&.then { _1.is_a?(::Array) ? _1.map { |t| type(t) }.reduce(:|) : type(_1) }
      allow_nil = options.delete(:allow_nil)&.then { call_factory(:allow_nil, _1) unless _1.nil? }

      other = options.map { |name, value| clause(name, value) }

      checker = type
      checker = (checker ? ([checker] + other) : other).reduce(:&) unless other.empty?
      checker = checker ? checker | allow_nil : allow_nil if allow_nil
      checker
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def clause(name, value)
      case value
      when ::Hash then Checker.single(name, value.fetch(:guard), value[:expectation])
      when ::Proc then Checker.single(name, value)
      when ::Array then value.map { |val| clause(name, val) }.reduce(:|)
      else call_factory(name, value)
      end
    end

    private

    def type(value)
      call_factory(:type, value)
    end

    def call_factory(name, value)
      Factory::REGISTRY.read(name).call(value)
    end
  end
end
