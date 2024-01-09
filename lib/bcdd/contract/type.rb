# frozen_string_literal: true

module BCDD::Contract
  # A module that can be used to create a type contract.
  #
  # @example
  # ValidNumber = ::BCDD::Contract::Type.new(
  #   message: '%p must be a valid number (numeric, not infinity or NaN)',
  #   checker: ->(arg) do
  #     is_nan = arg.respond_to?(:nan?) && arg.nan?
  #     is_inf = arg.respond_to?(:infinite?) && arg.infinite?
  #
  #     arg.is_a?(::Numeric) && !(is_nan || is_inf)
  #   end
  # )
  module Type
    METHODS = <<~RUBY
      def self.===(value); CHECKER.call(value); end

      def self.[](value)
        return value if self === value

        raise BCDD::Contract::Error, format(MESSAGE, value)
      end

      def self.to_proc
        ->(value) { self[value] }
      end
    RUBY

    def self.new(checker: nil, message: '%p is invalid')
      (checker.is_a?(::Proc) && checker.lambda?) or raise ArgumentError, 'checker: must be a lambda'
      checker.arity == 1 or raise ArgumentError, 'checker: must accept one argument'

      mod = Module.new
      mod.const_set(:MESSAGE, message)
      mod.const_set(:CHECKER, checker)
      mod.module_eval(METHODS, __FILE__, __LINE__ + 1)
      mod
    end
  end
end
