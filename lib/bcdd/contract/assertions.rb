# frozen_string_literal: true

module BCDD::Contract
  module Assertions
    def assert!(...)
      ::BCDD::Contract.assert!(...)
    end

    def refute!(...)
      ::BCDD::Contract.refute!(...)
    end

    def assert(...)
      ::BCDD::Contract.assert(...)
    end

    def refute(...)
      ::BCDD::Contract.refute(...)
    end
  end
end
