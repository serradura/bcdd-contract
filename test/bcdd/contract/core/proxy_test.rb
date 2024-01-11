# frozen_string_literal: true

require 'test_helper'

module BCDD::Contract
  class CoreProxyTest < Minitest::Test
    module Calc
      class Contract < Core::Proxy
        ValidNumber = ::BCDD::Contract::Unit.new ->(value, err) do
          err << '%p must be numeric' and return unless value.is_a?(::Numeric)

          err << '%p cannot be nan' and return if value.respond_to?(:nan?) && value.nan?

          err << '%p cannot be infinite' if value.respond_to?(:infinite?) && value.infinite?
        end

        def add(a, b)
          +ValidNumber[a]
          +ValidNumber[b]

          +ValidNumber[object.add(a, b)]
        end

        def subtract(a, b)
          +ValidNumber[a]
          +ValidNumber[b]

          +ValidNumber[object.subtract(a, b)]
        end

        CannotBeZero = ::BCDD::Contract::Unit.new ->(arg, err) do
          err << '%p cannot be zero' if arg.zero?
        end

        def divide(a, b)
          +ValidNumber[a]
          +ValidNumber[b] && +CannotBeZero[b]

          +ValidNumber[object.divide(a, b)]
        end
      end

      class Operations
        def initialize(calc)
          @calc = Contract.new(calc)
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

      assert_equal('"2" must be numeric', err1a.message)
      assert_equal('"1" must be numeric', err2a.message)
      assert_equal('0 cannot be zero', err3a.message)

      assert_equal('"1" must be numeric', err1b.message)
      assert_equal('"2" must be numeric', err2b.message)
      assert_equal('"1" must be numeric', err3b.message)
    end

    test '.to_proc' do
      contracts = [NamespaceA::CalcOperations.new, NamespaceB::CalcOperations].map(&Calc::Contract)

      assert_equal [Calc::Contract, Calc::Contract], contracts.map(&:class)

      assert_equal 3, contracts[0].add(1, 2)
      assert_equal 3, contracts[1].add(1, 2)
    end

    test '.new' do
      object = Object.new

      instance = Core::Proxy.new(object)

      assert_instance_of Core::Proxy, instance
    end

    test '#object' do
      object = Object.new

      instance = Core::Proxy.new(object)

      assert_same object, instance.object
    end
  end
end
