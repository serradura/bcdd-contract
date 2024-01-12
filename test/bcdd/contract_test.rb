# frozen_string_literal: true

require 'test_helper'

class BCDD::ContractTest < Minitest::Test
  NotNil = BCDD::Contract.unit ->(value, err) do
    err << 'cannot be nil' if value.nil?
  end

  NumericProxy = BCDD::Contract.proxy do
    def +(other)
      other.is_a?(::Numeric) or raise TypeError, "#{other} is not a number"

      object + other
    end
  end

  test 'that it has a version number' do
    refute_nil ::BCDD::Contract::VERSION
  end

  test '.unit' do
    assert_predicate NotNil[1], :valid?
    refute_predicate NotNil[nil], :valid?
  end

  test '.proxy' do
    assert_operator NumericProxy, :<, BCDD::Contract::Proxy

    assert_equal 3, NumericProxy[1] + 2

    assert_raises(TypeError, ':a is not a number') { NumericProxy[1] + :a }
  end

  test '.error!' do
    assert_raises(BCDD::Contract::Error, 'An awesome message') { BCDD::Contract.error! 'An awesome message' }
  end
end
