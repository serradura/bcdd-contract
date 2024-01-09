# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::TypeTest < Minitest::Test
  ValidNumber = ::BCDD::Contract::Type.new(
    message: '%p must be a valid number (numeric, not infinity or NaN)',
    checker: ->(arg) do
      is_nan = arg.respond_to?(:nan?) && arg.nan?
      is_inf = arg.respond_to?(:infinite?) && arg.infinite?

      arg.is_a?(::Numeric) && !(is_nan || is_inf)
    end
  )

  test 'default message' do
    mod = ::BCDD::Contract::Type.new(checker: ->(arg) { arg.is_a?(::Numeric) })

    err = assert_raises(BCDD::Contract::Error) { mod['1'] }

    assert_equal('"1" is invalid', err.message)
  end

  test 'the checker validation' do
    err1 = assert_raises(ArgumentError) { ::BCDD::Contract::Type.new(checker: Object.new) }
    err2 = assert_raises(ArgumentError) { ::BCDD::Contract::Type.new(checker: proc {}) }
    err3 = assert_raises(ArgumentError) { ::BCDD::Contract::Type.new(checker: -> {}) }

    assert_equal('checker: must be a lambda', err1.message)
    assert_equal('checker: must be a lambda', err2.message)
    assert_equal('checker: must accept one argument', err3.message)
  end

  test 'that is a module' do
    assert_instance_of Module, ValidNumber

    assert_equal('BCDD::Contract::TypeTest::ValidNumber', ValidNumber.name)

    assert_equal('BCDD::Contract::TypeTest::ValidNumber', ValidNumber.inspect)
  end

  test '.===()' do
    assert ValidNumber === 1
    assert ValidNumber === 1r
    assert ValidNumber === 1.0

    refute_operator ValidNumber, :===, '1'
    refute_operator ValidNumber, :===, (0.0 / 0.0)
    refute_operator ValidNumber, :===, (1.0 / 0.0)
  end

  test '.[]()' do
    assert_equal(1, ValidNumber[1])
    assert_equal(1r, ValidNumber[1r])
    assert_in_delta(1.0, ValidNumber[1.0])

    err1 = assert_raises(BCDD::Contract::Error) { ValidNumber['1'] }
    err2 = assert_raises(BCDD::Contract::Error) { ValidNumber[0.0 / 0.0] }
    err3 = assert_raises(BCDD::Contract::Error) { ValidNumber[1.0 / 0.0] }

    assert_equal('"1" must be a valid number (numeric, not infinity or NaN)', err1.message)
    assert_equal('NaN must be a valid number (numeric, not infinity or NaN)', err2.message)
    assert_equal('Infinity must be a valid number (numeric, not infinity or NaN)', err3.message)
  end

  test '.to_proc' do
    numbers = [1, 1r, 1.0].map(&ValidNumber)

    assert_equal([1, 1r, 1.0], numbers)

    err1 = assert_raises(BCDD::Contract::Error) { ['1', 1r, 1.0].map(&ValidNumber) }
    err2 = assert_raises(BCDD::Contract::Error) { [1, 0.0 / 0.0, 1.0].map(&ValidNumber) }
    err3 = assert_raises(BCDD::Contract::Error) { [1, 1r, 1.0 / 0.0].map(&ValidNumber) }

    assert_equal('"1" must be a valid number (numeric, not infinity or NaN)', err1.message)
    assert_equal('NaN must be a valid number (numeric, not infinity or NaN)', err2.message)
    assert_equal('Infinity must be a valid number (numeric, not infinity or NaN)', err3.message)
  end
end
