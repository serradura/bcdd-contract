# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::ProvisionsSingletonTest < Minitest::Test
  IsEmpty = contract.unit!(name: :empty, guard: proc(&:empty?))
  IsFilled = contract.unit!(name: :filled, guard: -> { !_1.empty? })

  test 'unit! creates a new class' do
    assert_kind_of Class, IsEmpty
    assert_kind_of Class, IsFilled
  end

  test 'the constructor alias' do
    instance1a = IsEmpty['']
    instance1b = IsEmpty.new('')

    assert_instance_of IsEmpty, instance1a
    assert_instance_of IsEmpty, instance1b

    assert_equal instance1a.to_h, instance1b.to_h

    instance2a = IsFilled['123']
    instance2b = IsFilled.new('123')

    assert_instance_of IsFilled, instance2a
    assert_instance_of IsFilled, instance2b

    assert_equal instance2a.to_h, instance2b.to_h
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
    checking1 = IsEmpty.new('')
    checking2 = IsEmpty.new([])

    assert_equal({ value: '', violations: {} }, checking1.to_h)
    assert_equal({ value: [], violations: {} }, checking2.to_h)

    checking3 = IsEmpty.new('123')
    checking4 = IsEmpty.new([1, 2, 3])

    assert_equal({ value: '123', violations: { empty: [true] } }, checking3.to_h)
    assert_equal({ value: [1, 2, 3], violations: { empty: [true] } }, checking4.to_h)

    checking5 = IsFilled.new('123')
    checking6 = IsFilled.new([1, 2, 3])

    assert_equal({ value: '123', violations: {} }, checking5.to_h)
    assert_equal({ value: [1, 2, 3], violations: {} }, checking6.to_h)

    checking7 = IsFilled.new('')
    checking8 = IsFilled.new([])

    assert_equal({ value: '', violations: { filled: [true] } }, checking7.to_h)
    assert_equal({ value: [], violations: { filled: [true] } }, checking8.to_h)
  end
end
