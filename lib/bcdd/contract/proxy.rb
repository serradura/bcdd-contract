# frozen_string_literal: true

module BCDD::Contract
  # A class to inherit to create a proxy object.
  # Which can be used to check the arguments and returned values of the proxy object's methods.
  #
  # @example
  # class Calculation < ::BCDD::Contract::Proxy
  #   ValidNumber = ::BCDD::Contract::Type.new(
  #     message: '%p must be a valid number (numeric, not infinity or NaN)',
  #     checker: ->(arg) do
  #       is_nan = arg.respond_to?(:nan?) && arg.nan?
  #       is_inf = arg.respond_to?(:infinite?) && arg.infinite?
  #
  #       arg.is_a?(::Numeric) && !(is_nan || is_inf)
  #     end
  #   )
  #
  #   CannotBeZero = ::BCDD::Contract::Type.new(
  #     message: '%p cannot be zero',
  #     checker: ->(arg) { arg != 0 }
  #   )
  #
  #   def divide(a, b)
  #     ValidNumber[a]
  #     ValidNumber[b] && CannotBeZero[b]
  #
  #     object.divide(a, b).tap(&ValidNumber)
  #   end
  #
  #   # ... other methods ...
  # end
  class Proxy
    def self.new(object)
      return object unless Config.instance.proxy_enabled

      instance = allocate
      instance.send(:initialize, object)
      instance
    end

    def self.to_proc
      ->(object) { new(object) }
    end

    attr_reader :object

    def initialize(object)
      @object = object
    end
  end
end
