# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::ValueUnionTest < Minitest::Test
  IsEmailOrNil = contract.with(type: String, format: /\A[^@\s]+@[^@\s]+\z/, allow_nil: true)

  FilledArrayOrHash = contract.with(type: { union: [Array, Hash] }, allow_empty: false)

  test 'the objects' do
    assert_instance_of BCDD::Contract::Value::Checker, IsEmailOrNil
    assert_instance_of BCDD::Contract::Value::Checker, FilledArrayOrHash
  end

  test 'the value checking' do
    checking0 = IsEmailOrNil.new(nil)
    checking1 = IsEmailOrNil['email@example.com']
    checking2 = IsEmailOrNil.new(1)
    checking3 = IsEmailOrNil['1']

    assert_equal({ value: nil, violations: {} }, checking0.to_h)
    assert_equal({ value: 'email@example.com', violations: {} }, checking1.to_h)
    assert_equal({ value: 1, violations: { type: [String], allow_nil: [true] } }, checking2.to_h)
    assert_equal({ value: '1', violations: { format: [/\A[^@\s]+@[^@\s]+\z/], allow_nil: [true] } }, checking3.to_h)

    checking4 = FilledArrayOrHash.new([1])
    checking5 = FilledArrayOrHash[{ one: 1 }]
    checking6 = FilledArrayOrHash.new([])
    checking7 = FilledArrayOrHash[{}]

    assert_equal({ value: [1], violations: {} }, checking4.to_h)
    assert_equal({ value: { one: 1 }, violations: {} }, checking5.to_h)

    assert_equal({ value: [], violations: { allow_empty: [false] } }, checking6.to_h)
    assert_equal({ value: {}, violations: { allow_empty: [false] } }, checking7.to_h)
  end
end
