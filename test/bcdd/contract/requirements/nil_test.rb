# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::RequirementsNilTest < Minitest::Test
  IsNil = contract.allow_nil!
  IsNotNil = contract.allow_nil!(false)

  test 'type! creates a new class' do
    assert_kind_of Class, IsNil
    assert_kind_of Class, IsNotNil

    assert_operator IsNil, :<, BCDD::Contract::Requirements::Object
    assert_operator IsNotNil, :<, BCDD::Contract::Requirements::Object
  end

  test 'the value checking' do
    checking1 = IsNil.new(nil)
    checking2 = IsNil.new('string')

    assert_equal({ value: nil, violations: {} }, checking1.to_h)
    assert_equal({ value: 'string', violations: { nil: [true] } }, checking2.to_h)

    checking3 = IsNotNil.new(:symbol)
    checking4 = IsNotNil.new(nil)

    assert_equal({ value: :symbol, violations: {} }, checking3.to_h)
    assert_equal({ value: nil, violations: { nil: [false] } }, checking4.to_h)
  end
end
