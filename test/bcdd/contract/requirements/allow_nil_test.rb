# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::RequirementsNilTest < Minitest::Test
  IsNil = contract.allow_nil!(true)
  IsNotNil = contract.allow_nil!(false)

  test 'allow_nil! object' do
    assert_instance_of BCDD::Contract::Requirements::Checker, IsNil
    assert_instance_of BCDD::Contract::Requirements::Checker, IsNotNil
  end

  test 'the value checking' do
    checking1 = IsNil[nil]
    checking2 = IsNil.new('string')

    assert_equal({ value: nil, violations: {} }, checking1.to_h)
    assert_equal({ value: 'string', violations: { allow_nil: [true] } }, checking2.to_h)

    checking3 = IsNotNil[:symbol]
    checking4 = IsNotNil.new(nil)

    assert_equal({ value: :symbol, violations: {} }, checking3.to_h)
    assert_equal({ value: nil, violations: { allow_nil: [false] } }, checking4.to_h)
  end
end
