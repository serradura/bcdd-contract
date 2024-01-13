# frozen_string_literal: true

module BCDD::Contract::Unit
  module Checker
    def [](value)
      Checking.new(checker, value)
    end

    def ===(value)
      self[value].valid?
    end

    def to_proc
      ->(value) { self[value] }
    end

    SequenceMapper = ->(strategies) do
      ->(value, err) { strategies.each { |strategy| strategy.call(value, err) if err.empty? } }
    end

    def &(other)
      other = Factory.instance.call(other)

      check_in_sequence = SequenceMapper.call([checker, other.checker])

      ::Module.new.extend(Checker).send(:setup, check_in_sequence)
    end

    def invariant(value)
      self[value].raise_validation_errors!

      output = yield(value)

      self[value].raise_validation_errors!

      output
    end

    protected

    attr_reader :checker

    def setup(checker)
      tap { @checker = checker }
    end

    private_constant :SequenceMapper
  end
end
