# frozen_string_literal: true

require 'test_helper'

class BCDD::ContractSingletonMethodsTest < Minitest::Test
  NumericProxy = BCDD::Contract.proxy do
    def +(other)
      other.is_a?(::Numeric) or raise TypeError, "#{other} is not a number"

      object + other
    end
  end

  test 'that it has a version number' do
    refute_nil ::BCDD::Contract::VERSION
  end

  test '.proxy' do
    assert_operator NumericProxy, :<, BCDD::Contract::Proxy

    assert_equal 3, NumericProxy[1] + 2

    assert_raises(TypeError, ':a is not a number') { NumericProxy[1] + :a }
  end

  test '.error!' do
    assert_raises(BCDD::Contract::Error, 'An awesome message') { BCDD::Contract.error! 'An awesome message' }
  end

  test '.assert!' do
    object = Object.new

    assert_same true, BCDD::Contract.assert!(true, 'must be true')
    assert_same object, BCDD::Contract.assert!(object, 'must be truthy')
    assert_same(3, BCDD::Contract.assert!(3, 'block outcome must be true') { _1 == 3 })
    assert_same(4, BCDD::Contract.assert!(4, 'block outcome must be truthy') { object })

    assert_raises(BCDD::Contract::Error, 'false') { BCDD::Contract.assert!(false, '%p') }
    assert_raises(BCDD::Contract::Error, 'An awesome message') { BCDD::Contract.assert!(false, 'An awesome message') }
    assert_raises(BCDD::Contract::Error, '(1) block returned false') do
      BCDD::Contract.assert!(1, '(%p) block returned falsey') { |one| one == 2 }
    end
    assert_raises(BCDD::Contract::Error, '2) block returned falsey') do
      BCDD::Contract.assert!(2, '(%p) block returned falsey') { nil }
    end
  end

  test '.assert' do
    object = Object.new

    assert_same true, BCDD::Contract.assert(true, 'must be true')
    assert_same object, BCDD::Contract.assert(object, 'must be truthy')
    assert_same(3, BCDD::Contract.assert(3, 'block outcome must be true') { _1 == 3 })
    assert_same(4, BCDD::Contract.assert(4, 'block outcome must be truthy') { object })

    assert_raises(BCDD::Contract::Error, 'false') { BCDD::Contract.assert(false, '%p') }
    assert_raises(BCDD::Contract::Error, 'An awesome message') { BCDD::Contract.assert(false, 'An awesome message') }
    assert_raises(BCDD::Contract::Error, '(1) block returned falsey') do
      BCDD::Contract.assert(1, '(%p) block returned falsey') { |one| one == 2 }
    end
    assert_raises(BCDD::Contract::Error, '2) block returned falsey') do
      BCDD::Contract.assert(2, '(%p) block returned falsey') { nil }
    end
  end

  test '.refute!' do
    assert_same false, BCDD::Contract.refute!(false, 'must be falsey')
    assert_nil BCDD::Contract.refute!(nil, 'must be falsey')
    assert_same(3, BCDD::Contract.refute!(3, 'block outcome must be false') { _1 != 3 })
    assert_same(4, BCDD::Contract.refute!(4, 'block outcome must be falsey') { nil })

    assert_raises(BCDD::Contract::Error, 'true') { BCDD::Contract.refute!(true, '%p') }
    assert_raises(BCDD::Contract::Error, 'An awesome message') { BCDD::Contract.refute!(true, 'An awesome message') }
    assert_raises(BCDD::Contract::Error, '(1) block returned true') do
      BCDD::Contract.refute!(1, '(%p) block returned true') { |one| one == 1 }
    end
    assert_raises(BCDD::Contract::Error, '(2) block returned truthy') do
      BCDD::Contract.refute!(2, '(%p) block returned truthy') { Object.new }
    end
  end

  test '.refute' do
    assert_same false, BCDD::Contract.refute!(false, 'must be falsey')
    assert_nil BCDD::Contract.refute!(nil, 'must be falsey')
    assert_same(3, BCDD::Contract.refute!(3, 'block outcome must be false') { _1 != 3 })
    assert_same(4, BCDD::Contract.refute!(4, 'block outcome must be falsey') { nil })

    assert_raises(BCDD::Contract::Error, 'true') { BCDD::Contract.refute!(true, '%p') }
    assert_raises(BCDD::Contract::Error, 'An awesome message') { BCDD::Contract.refute!(true, 'An awesome message') }
    assert_raises(BCDD::Contract::Error, '(1) block returned true') do
      BCDD::Contract.refute!(1, '(%p) block returned true') { |one| one == 1 }
    end
    assert_raises(BCDD::Contract::Error, '(2) block returned truthy') do
      BCDD::Contract.refute!(2, '(%p) block returned truthy') { Object.new }
    end
  end

  test '.to_proc' do
    str, sym = [String, Symbol].map(&BCDD::Contract)

    [str, sym].each do |contract|
      assert_kind_of BCDD::Contract.const_get(:Core)::Checker, contract
    end

    assert_operator str, :===, 'string'
    assert_operator sym, :===, :symbol
    refute_operator str, :===, :symbol
    refute_operator sym, :===, 'string'
  end

  test '.new' do
    str, sym = BCDD::Contract.new(String), BCDD::Contract.new(Symbol)

    [str, sym].each do |contract|
      assert_kind_of BCDD::Contract.const_get(:Core)::Checker, contract
    end

    assert_operator str, :===, 'string'
    assert_operator sym, :===, :symbol
    refute_operator str, :===, :symbol
    refute_operator sym, :===, 'string'
  end

  test '.new alias' do
    str, sym = BCDD::Contract[String], BCDD::Contract[Symbol]

    [str, sym].each do |contract|
      assert_kind_of BCDD::Contract.const_get(:Core)::Checker, contract
    end

    assert_operator str, :===, 'string'
    assert_operator sym, :===, :symbol
    refute_operator str, :===, :symbol
    refute_operator sym, :===, 'string'
  end

  test '.Contract' do
    str, sym = BCDD::Contract(String), BCDD::Contract(Symbol)

    [str, sym].each do |contract|
      assert_kind_of BCDD::Contract.const_get(:Core)::Checker, contract
    end

    assert_operator str, :===, 'string'
    assert_operator sym, :===, :symbol
    refute_operator str, :===, :symbol
    refute_operator sym, :===, 'string'
  end
end
