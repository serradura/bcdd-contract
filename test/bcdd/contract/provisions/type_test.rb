# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::ProvisionsTypeTest < Minitest::Test
  IsString = contract.type!(String)
  IsSymbol = contract.type!(Symbol)

  test 'type! creates a new class' do
    assert_kind_of Class, IsString
    assert_kind_of Class, IsSymbol

    assert_operator IsString, :<, BCDD::Contract::Provisions::Object
    assert_operator IsSymbol, :<, BCDD::Contract::Provisions::Object
  end

  test 'the value checking' do
    checking1 = IsString.new('string')
    checking2 = IsString.new(:symbol)

    assert_equal({ value: 'string', violations: {} }, checking1.to_h)
    assert_equal({ value: :symbol, violations: { type: [String] } }, checking2.to_h)

    checking3 = IsSymbol.new(:symbol)
    checking4 = IsSymbol.new('string')

    assert_equal({ value: :symbol, violations: {} }, checking3.to_h)
    assert_equal({ value: 'string', violations: { type: [Symbol] } }, checking4.to_h)
  end
end
