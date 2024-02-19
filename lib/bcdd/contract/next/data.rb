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

          value.key?(:violations) ? ExtractViolations[value[:violations]] : value
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

    def self.data(strategy, options)
      schema = options.delete(:schema).then { _1 or Error[':schema must be provided'] }

      options[:allow_empty] = false unless options.delete(:allow_empty)

      data_req = Value.with(options)
      schema_req = with(schema, transform_values: data_req.clauses[:type].include?(::Hash))

      strategy.new(data_req, schema_req)
    end

    # rubocop:disable Style/MultipleComparison
    def self.with(options, transform_values: false)
      unless options.key?(:schema)
        return transform_values ? options.transform_values! { with(_1) } : Value.with(options)
      end

      type = options[:type].then { _1.is_a?(::Array) ? _1 : [_1] }

      return data(ListSchema, options) if type.any? { _1 == ::Array || _1 == ::Set }
      return data(HashSchema, options) if type.any? { _1 == ::Hash }

      Value.with(options)
    end
    # rubocop:enable Style/MultipleComparison
  end
end
