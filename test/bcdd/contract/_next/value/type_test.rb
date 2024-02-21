# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::ValueTypeTest < Minitest::Test
  IsString = contract.with(type: String)
  IsSymbol = contract.with(type: Symbol)

  test 'the objects' do
    assert_instance_of BCDD::Contract::Value::Checker, IsString
    assert_instance_of BCDD::Contract::Value::Checker, IsSymbol
  end

  test 'the value checking' do
    checking1 = IsString['string']
    checking2 = IsString.new(:symbol)

    assert_equal({ value: 'string', violations: {} }, checking1.to_h)
    assert_equal({ value: :symbol, violations: { type: [String] } }, checking2.to_h)

    checking3 = IsSymbol[:symbol]
    checking4 = IsSymbol.new('string')

    assert_equal({ value: :symbol, violations: {} }, checking3.to_h)
    assert_equal({ value: 'string', violations: { type: [Symbol] } }, checking4.to_h)
  end
end
