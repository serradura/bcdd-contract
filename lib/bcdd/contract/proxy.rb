# frozen_string_literal: true

module BCDD::Contract
  # A class to inherit to create a proxy object.
  # Which can be used to check the arguments and returned values of the proxy object's methods.
  #
  # @example
  # class Calculation < ::BCDD::Contract::Proxy
  #   ValidNumber = ::BCDD::Contract::Unit.new ->(value, err) do
  #     err << '%p must be numeric' and return unless value.is_a?(::Numeric)
  #     err << '%p cannot be nan' and return if value.respond_to?(:nan?) && value.nan?
  #     err << '%p cannot be infinite' if value.respond_to?(:infinite?) && value.infinite?
  #   end
  #
  #   CannotBeZero = ::BCDD::Contract::Unit.new ->(arg, err) do
  #     err << '%p cannot be zero' if arg.zero?
  #   end
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
