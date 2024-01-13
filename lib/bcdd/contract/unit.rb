# frozen_string_literal: true

module BCDD::Contract
  # A module that can be used to create contract checkers
  # (a module that can be used to perform validations and type checkings).
  #
  # @example
  # cannot_be_inf = ->(val, err) { err << '%p cannot be infinite' if val.respond_to?(:infinite?) && val.infinite? }
  # cannot_be_nan = ->(val, err) { err << '%p cannot be nan' if val.respond_to?(:nan?) && val.nan? }
  #
  # CannotBeInfinity = ::BCDD::Contract::Unit.new(cannot_be_inf)
  # CannotBeNaN      = ::BCDD::Contract::Unit.new(cannot_be_nan)
  # IsNumeric        = ::BCDD::Contract::Unit[Numeric]
  #
  # ValidNumber = IsNumeric & CannotBeNaN & CannotBeInfinity
  module Unit
    require_relative 'unit/checker'
    require_relative 'unit/checking'
    require_relative 'unit/factory'

    def self.new(checker)
      Factory.instance.unit(checker)
    end

    def self.[](arg)
      Factory.instance.call(arg)
    end
  end
end
