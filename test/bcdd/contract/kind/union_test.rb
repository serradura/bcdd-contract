# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::KindUnionTest < Minitest::Test
  IsEmailOrNil = (contract.type!(String) & contract.format!(/\A[^@\s]+@[^@\s]+\z/)) | contract.nil!

  is_filled = contract.unit!(name: :filled, check: -> { !_1.empty? })

  FilledArrayOrHash = (contract.type!(Array) | contract.type!(Hash)) & is_filled

  test 'union creates a new class' do
    assert_kind_of Class, IsEmailOrNil
    assert_kind_of Class, FilledArrayOrHash

    assert_operator IsEmailOrNil, :<, BCDD::Contract::Kind::Unit
    assert_operator FilledArrayOrHash, :<, BCDD::Contract::Kind::Unit
  end

  test 'the value checking' do
    checking0 = IsEmailOrNil.new(nil)
    checking1 = IsEmailOrNil.new('email@example.com')
    checking2 = IsEmailOrNil.new(1)
    checking3 = IsEmailOrNil.new('1')

    assert_equal({ value: nil, violations: {} }, checking0.to_h)
    assert_equal({ value: 'email@example.com', violations: {} }, checking1.to_h)
    assert_equal({ value: 1, violations: { type: [String], nil: [true] } }, checking2.to_h)
    assert_equal({ value: '1', violations: { format: [/\A[^@\s]+@[^@\s]+\z/], nil: [true] } }, checking3.to_h)

    checking4 = FilledArrayOrHash.new([1])
    checking5 = FilledArrayOrHash.new({one: 1})
    checking6 = FilledArrayOrHash.new([])
    checking7 = FilledArrayOrHash.new({})

    assert_equal({ value: [1], violations: {} }, checking4.to_h)
    assert_equal({ value: {one: 1}, violations: {} }, checking5.to_h)

    assert_equal({ value: [], violations: { filled: [true] } }, checking6.to_h)
    assert_equal({ value: {}, violations: { filled: [true] } }, checking7.to_h)
  end
end
