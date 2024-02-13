# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::RequirementsUnionTest < Minitest::Test
  IsEmailOrNil = (contract.type!(String) & contract.format!(/\A[^@\s]+@[^@\s]+\z/)) | contract.allow_nil!

  is_filled = contract.clause!(name: :filled, guard: -> { !_1.empty? })

  FilledArrayOrHash = (contract.type!(Array) | contract.type!(Hash)) & is_filled

  test 'union object' do
    assert_instance_of BCDD::Contract::Requirements::Checker, IsEmailOrNil
    assert_instance_of BCDD::Contract::Requirements::Checker, FilledArrayOrHash
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

    assert_equal({ value: [], violations: { filled: [true] } }, checking6.to_h)
    assert_equal({ value: {}, violations: { filled: [true] } }, checking7.to_h)
  end
end
