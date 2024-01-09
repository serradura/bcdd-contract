# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::ProxyTest < Minitest::Test
  module Calc
    class Interface < ::BCDD::Contract::Proxy
      ValidNumber = ::BCDD::Contract::Type.new(
        message: '%p must be a valid number (numeric, not infinity or NaN)',
        checker: ->(arg) do
          is_nan = arg.respond_to?(:nan?) && arg.nan?
          is_inf = arg.respond_to?(:infinite?) && arg.infinite?

          arg.is_a?(::Numeric) && !(is_nan || is_inf)
        end
      )

      def add(a, b)
        ValidNumber[a]
        ValidNumber[b]

        ValidNumber[object.add(a, b)]
      end

      def subtract(a, b)
        ValidNumber[a]
        ValidNumber[b]

        object.subtract(a, b).tap(&ValidNumber)
      end

      CannotBeZero = ::BCDD::Contract::Type.new(
        message: '%p cannot be zero',
        checker: ->(arg) { arg != 0 }
      )

      def divide(a, b)
        ValidNumber[a]
        ValidNumber[b] && CannotBeZero[b]

        object.divide(a, b).tap(&ValidNumber)
      end
    end

    class Operations
      def initialize(calc)
        @calc = Interface.new(calc)
      end

      def add(...); @calc.add(...); end
      def subtract(...); @calc.subtract(...); end
      def divide(...); @calc.divide(...); end
    end
  end

  module NamespaceA
    class CalcOperations
      def add(a, b); a + b; end
      def subtract(a, b); a - b; end
      def divide(a, b); a / b; end
    end
  end

  module NamespaceB
    module CalcOperations
      def self.add(a, b); a + b; end
      def self.subtract(a, b); a - b; end
      def self.divide(a, b); a / b; end
    end
  end

  test 'dependency inversion' do
    calc1 = Calc::Operations.new(NamespaceA::CalcOperations.new)
    calc2 = Calc::Operations.new(NamespaceB::CalcOperations)

    assert_equal 3, calc1.add(1, 2)
    assert_equal 3, calc2.add(1, 2)

    assert_equal(-1, calc1.subtract(1, 2))
    assert_equal(-1, calc2.subtract(1, 2))

    assert_in_delta(0.5, calc1.divide(1.0, 2))
    assert_in_delta(0.5, calc2.divide(1.0, 2))
  end

  test 'contract errors' do
    calc1 = Calc::Operations.new(NamespaceA::CalcOperations.new)
    calc2 = Calc::Operations.new(NamespaceB::CalcOperations)

    err1a = assert_raises(BCDD::Contract::Error) { calc1.add(1, '2') }
    err2a = assert_raises(BCDD::Contract::Error) { calc1.subtract('1', 2) }
    err3a = assert_raises(BCDD::Contract::Error) { calc1.divide(1, 0) }

    err1b = assert_raises(BCDD::Contract::Error) { calc2.add('1', 2) }
    err2b = assert_raises(BCDD::Contract::Error) { calc2.subtract(1, '2') }
    err3b = assert_raises(BCDD::Contract::Error) { calc2.divide('1', 0) }

    assert_equal('"2" must be a valid number (numeric, not infinity or NaN)', err1a.message)
    assert_equal('"1" must be a valid number (numeric, not infinity or NaN)', err2a.message)
    assert_equal('0 cannot be zero', err3a.message)

    assert_equal('"1" must be a valid number (numeric, not infinity or NaN)', err1b.message)
    assert_equal('"2" must be a valid number (numeric, not infinity or NaN)', err2b.message)
    assert_equal('"1" must be a valid number (numeric, not infinity or NaN)', err3b.message)
  end

  test '.to_proc' do
    interfaces = [NamespaceA::CalcOperations.new, NamespaceB::CalcOperations].map(&Calc::Interface)

    assert_equal [Calc::Interface, Calc::Interface], interfaces.map(&:class)

    assert_equal 3, interfaces[0].add(1, 2)
    assert_equal 3, interfaces[1].add(1, 2)
  end
end
