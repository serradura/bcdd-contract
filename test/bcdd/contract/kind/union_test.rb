# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::KindUnionTest < Minitest::Test
  IsEmailOrNil = (contract.type!(String) & contract.format!(/\A[^@\s]+@[^@\s]+\z/)) | contract.nil!

  is_filled = contract.unit!(name: :filled, check: -> { !_1.empty? })

  FilleArrayOrHash = (contract.type!(Array) | contract.type!(Hash)) & is_filled

  test 'the value checking' do
    checking0 = IsEmailOrNil.new(nil)
    checking1 = IsEmailOrNil.new('email@example.com')
    checking2 = IsEmailOrNil.new(1)
    checking3 = IsEmailOrNil.new('1')

    assert_equal({ value: nil, violations: {} }, checking0.to_h)
    assert_equal({ value: 'email@example.com', violations: {} }, checking1.to_h)
    assert_equal({ value: 1, violations: { type: [String], nil: [true] } }, checking2.to_h)
    assert_equal({ value: '1', violations: { format: [/\A[^@\s]+@[^@\s]+\z/], nil: [true] } }, checking3.to_h)

    checking4 = FilleArrayOrHash.new([1])
    checking5 = FilleArrayOrHash.new({one: 1})
    checking6 = FilleArrayOrHash.new([])
    checking7 = FilleArrayOrHash.new({})

    assert_equal({ value: [1], violations: {} }, checking4.to_h)
    assert_equal({ value: {one: 1}, violations: {} }, checking5.to_h)

    assert_equal({ value: [], violations: { filled: [true] } }, checking6.to_h)
    assert_equal({ value: {}, violations: { filled: [true] } }, checking7.to_h)
  end
end
