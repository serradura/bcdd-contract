# frozen_string_literal: true

module BCDD::Contract
  # A class to inherit to create proxy objects.
  # Which can be used to check the arguments and returned values of the proxy object's methods.
  #
  # @example
  # class Calculation < ::BCDD::Contract::Proxy
  #   ValidNumber = ::BCDD::Contract[->(value, err) do
  #     err << '%p must be numeric' and return unless value.is_a?(::Numeric)
  #     err << '%p cannot be nan' and return if value.respond_to?(:nan?) && value.nan?
  #     err << '%p cannot be infinite' if value.respond_to?(:infinite?) && value.infinite?
  #   end]
  #
  #   CannotBeZero = ::BCDD::Contract[->(arg, err) do
  #     err << '%p cannot be zero' if arg.zero?
  #   end]
  #
  #   def divide(a, b)
  #     +ValidNumber[a]
  #     +ValidNumber[b] && +CannotBeZero[b]
  #
  #     +ValidNumber[object.divide(a, b)]
  #   end
  #
  #   # ... other methods ...
  # end
  class Proxy < Core::Proxy
    # A class to inherit to create a proxy object that is always enabled.
    AlwaysEnabled = ::Class.new(Core::Proxy)

    def self.new(object)
      return object unless Config.instance.proxy_enabled

      instance = allocate
      instance.send(:initialize, object)
      instance
    end
  end
end
