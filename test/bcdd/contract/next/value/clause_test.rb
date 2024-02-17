# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::ValueClauseTest < Minitest::Test
  IsEmpty = contract.with(empty: proc(&:empty?))
  IsFilled = contract.with(filled: -> { !_1.empty? })

  test 'the objects' do
    assert_instance_of BCDD::Contract::Value::Checker, IsEmpty
    assert_instance_of BCDD::Contract::Value::Checker, IsFilled
  end

  test '#value' do
    value1 = ''
    value2 = '123'

    assert_same value1, IsEmpty.new(value1).value
    assert_same value2, IsEmpty.new(value2).value

    assert_same value1, IsFilled.new(value1).value
    assert_same value2, IsFilled.new(value2).value
  end

  test '#violations' do
    assert_equal({}, IsEmpty.new('').violations)
    assert_equal({ empty: [true] }, IsEmpty.new('123').violations)

    assert_equal({ filled: [true] }, IsFilled.new('').violations)
    assert_equal({}, IsFilled.new('123').violations)
  end

  test 'the value checking' do
    checking1 = IsEmpty['']
    checking2 = IsEmpty.new([])

    assert_equal({ value: '', violations: {} }, checking1.to_h)
    assert_equal({ value: [], violations: {} }, checking2.to_h)

    checking3 = IsEmpty['123']
    checking4 = IsEmpty.new([1, 2, 3])

    assert_equal({ value: '123', violations: { empty: [true] } }, checking3.to_h)
    assert_equal({ value: [1, 2, 3], violations: { empty: [true] } }, checking4.to_h)

    checking5 = IsFilled['123']
    checking6 = IsFilled.new([1, 2, 3])

    assert_equal({ value: '123', violations: {} }, checking5.to_h)
    assert_equal({ value: [1, 2, 3], violations: {} }, checking6.to_h)

    checking7 = IsFilled['']
    checking8 = IsFilled.new([])

    assert_equal({ value: '', violations: { filled: [true] } }, checking7.to_h)
    assert_equal({ value: [], violations: { filled: [true] } }, checking8.to_h)
  end
end
