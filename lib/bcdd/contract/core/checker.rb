# frozen_string_literal: true

module BCDD::Contract
  module Core::Checker
    def [](value)
      checking.new(strategy, value)
    end

    def ===(value)
      self[value].valid?
    end

    def to_proc
      ->(value) { self[value] }
    end

    def invariant(value)
      self[value].raise_validation_errors!

      output = yield(value)

      self[value].raise_validation_errors!

      output
    end

    protected

    def checking
      const_get(:CHECKING, false)
    end

    def strategy
      const_get(:STRATEGY, false)
    end
  end
end
