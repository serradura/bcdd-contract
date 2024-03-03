# frozen_string_literal: true

module BCDD::Contract
  module Data
    class Checking < Value::Checking
      def to_h
        { value: value, violations: @violations }
      end

      ExtractViolations = ->(violations) do
        violations.transform_values do |value|
          next value unless value.is_a?(::Hash)

          if value.key?(:violations)
            ExtractViolations[value[:violations]]
          else
            value.transform_values do |vvalue|
              vvalue.is_a?(::Hash) && vvalue.key?(:violations) ? ExtractViolations[vvalue[:violations]] : vvalue
            end
          end
        end
      end

      def violations
        ExtractViolations[@violations]
      end
    end

    class Schema
      attr_reader :data_requirements, :schema_requirements

      private :data_requirements, :schema_requirements

      def initialize(data_requirements, schema_requirements)
        @data_requirements = data_requirements
        @schema_requirements = schema_requirements
        @data_and_schema_checker = checker[data_requirements, schema_requirements]
      end

      def clauses
        Error['must be implemented']
      end

      def new(value)
        Checking.new(value, @data_and_schema_checker)
      end

      alias [] new

      def invariant(value)
        new(value).raise_validation_errors!

        output = yield(value)

        new(value).raise_validation_errors!

        output
      end

      def ===(value)
        new(value).valid?
      end

      def inspect
        Error['must be implemented']
      end

      alias to_s inspect

      private

      def checker
        self.class.const_get(:Checker, false)
      end
    end

    class ListSchema < Schema
      Checker = ->(data_requirements, schema_requirements) do
        ->(value, violations:) do
          data_requirements.send(:requirements).call(value, violations: violations)

          if violations.empty? && !(value.nil? || value.empty?)
            value.each_with_index do |vval, index|
              val_checking = schema_requirements.new(vval)

              violations[index] = val_checking.to_h if val_checking.invalid?
            end
          end

          violations
        end
      end

      def clauses
        data_requirements.clauses.merge(schema: schema_requirements.clauses)
      end

      def inspect
        "(#{data_requirements.inspect} [#{schema_requirements.inspect}])"
      end
    end

    class HashSchema < Schema
      Checker = ->(data_requirements, schema_requirements) do
        ->(value, violations:) do
          data_requirements.send(:requirements).call(value, violations: violations)

          if violations.empty? && !(value.nil? || value.empty?)
            schema_requirements.each do |skey, item_requirements|
              val_checking = item_requirements.new(value[skey])

              violations[skey] = val_checking.to_h if val_checking.invalid?
            end
          end

          violations
        end
      end

      def clauses
        data_requirements.clauses.merge(schema: schema_requirements.transform_values(&:clauses))
      end

      def inspect
        schema_inspect = schema_requirements.map { |key, val| "#{key}: #{val.inspect}" }.join(', ')

        "(#{data_requirements.inspect} {#{schema_inspect}})"
      end
    end

    class Pairs
      attr_reader :data_requirements, :first_requirements, :second_requirements

      private :data_requirements, :first_requirements, :second_requirements

      def initialize(data_requirements, first_requirements, second_requirements)
        @data_requirements = data_requirements
        @first_requirements = first_requirements
        @second_requirements = second_requirements
        @data_and_schema_checker = checker[data_requirements, first_requirements, second_requirements]
      end

      def clauses
        Error['must be implemented']
      end

      def new(value)
        Checking.new(value, @data_and_schema_checker)
      end

      alias [] new

      def invariant(value)
        new(value).raise_validation_errors!

        output = yield(value)

        new(value).raise_validation_errors!

        output
      end

      def ===(value)
        new(value).valid?
      end

      def inspect
        Error['must be implemented']
      end

      alias to_s inspect

      private

      def checker
        self.class.const_get(:Checker, false)
      end
    end

    class HashKeyValue < Pairs
      Checker = ->(data_requirements, key_requirements, value_requirements) do
        ->(value, violations:) do
          data_requirements.send(:requirements).call(value, violations: violations)

          if violations.empty? && !(value.nil? || value.empty?)
            value.each do |vkey, vvalue|
              result = {}

              key_checking = key_requirements.new(vkey)
              value_checking = value_requirements.new(vvalue)

              result[:key] = key_checking.to_h if key_checking.invalid?
              result[:value] = value_checking.to_h if value_checking.invalid?

              violations[vkey] = result unless result.empty?
            end
          end

          violations
        end
      end

      def clauses
        pairs = { key: first_requirements.clauses, value: second_requirements.clauses }

        data_requirements.clauses.merge(pairs: pairs)
      end

      def inspect
        key_inspect = "key: #{first_requirements.inspect}"
        value_inspect = "value: #{second_requirements.inspect}"

        "(#{data_requirements.inspect} (pairs {#{key_inspect}, #{value_inspect}}))"
      end
    end

    module Create
      def self.schema(strategy, options)
        schema = options.delete(:schema)

        options[:allow_empty] = false unless options.delete(:allow_empty)

        data_req = Value::Create.with(options)
        schema_req = with(schema, transform_values: data_req.clauses[:type].include?(::Hash))

        strategy.new(data_req, schema_req)
      end

      def self.pairs(strategy, options)
        pairs = options.delete(:pairs)

        first = pairs.delete(:key).then { _1 || Error[':key is required'] }
        second = pairs.delete(:value).then { _1 || Error[':value is required'] }

        options[:allow_empty] = false unless options.delete(:allow_empty)

        data_req = Value::Create.with(options)
        first_req = with(first)
        second_req = with(second)

        strategy.new(data_req, first_req, second_req)
      end

      def self.data(type, options)
        has_pairs = options.key?(:pairs)
        has_schema = options.key?(:schema)

        has_pairs && has_schema and Error[':pairs and :schema are mutually exclusive']

        if type.any? { _1 == ::Hash }
          has_schema ? schema(HashSchema, options) : pairs(HashKeyValue, options)
        else
          schema(ListSchema, options)
        end
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def self.with(options, transform_values: false)
        return options if options.is_a?(Value::Checker) || options.is_a?(Schema) || options.is_a?(Pairs)

        unless options?(options)
          return transform_values ? options.transform_values! { with(_1) } : Value::Create.with(options)
        end

        type = options[:type].then { _1.is_a?(::Array) ? _1 : [_1] }

        type?(type) ? data(type, options) : Value::Create.with(options)
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def self.options?(options)
        options.key?(:schema) || options.key?(:pairs)
      end

      # rubocop:disable Style/MultipleComparison
      def self.type?(type)
        type.any? { _1 == ::Array || _1 == ::Set || _1 == ::Hash }
      end
      # rubocop:enable Style/MultipleComparison
    end
  end
end
