# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::UnitTest < Minitest::Test
  ValidNumber = ::BCDD::Contract::Unit.new ->(value, err) do
    err << '%p must be numeric' and return unless value.is_a?(::Numeric)

    err << '%p cannot be nan' and return if value.respond_to?(:nan?) && value.nan?

    err << '%p cannot be infinite' if value.respond_to?(:infinite?) && value.infinite?
  end

  test 'the checking: argument validation' do
    err1 = assert_raises(ArgumentError) { ::BCDD::Contract::Unit.new(Object.new) }
    err2 = assert_raises(ArgumentError) { ::BCDD::Contract::Unit.new(proc {}) }
    err3 = assert_raises(ArgumentError) { ::BCDD::Contract::Unit.new(-> {}) }

    assert_equal('must be a lambda', err1.message)
    assert_equal('must be a lambda', err2.message)
    assert_equal('must have two arguments (value, errors)', err3.message)
  end

  test 'that is a module' do
    assert_instance_of Module, ValidNumber

    assert_equal('BCDD::Contract::UnitTest::ValidNumber', ValidNumber.name)

    assert_equal('BCDD::Contract::UnitTest::ValidNumber', ValidNumber.inspect)
  end

  test '.===' do
    assert ValidNumber === 1
    assert ValidNumber === 1r
    assert ValidNumber === 1.0

    refute_operator ValidNumber, :===, '1'
    refute_operator ValidNumber, :===, (0.0 / 0.0)
    refute_operator ValidNumber, :===, (1.0 / 0.0)
  end

  test 'the value return or a validation error' do
    assert_equal(1, +ValidNumber[1])
    assert_equal(1r, +ValidNumber[1r])
    assert_in_delta(1.0, +ValidNumber[1.0])

    assert_equal(1, !ValidNumber[1])
    assert_equal(1r, !ValidNumber[1r])
    assert_in_delta(1.0, !ValidNumber[1.0])

    assert_equal(1, ValidNumber[1].value_or_err!)
    assert_equal(1r, ValidNumber[1r].value_or_err!)
    assert_in_delta(1.0, ValidNumber[1.0].value_or_err!)

    assert_raises(BCDD::Contract::Error, '"1" must be numeric') { +ValidNumber['1'] }
    assert_raises(BCDD::Contract::Error, 'NaN cannot be nan') { +ValidNumber[0.0 / 0.0] }
    assert_raises(BCDD::Contract::Error, 'Infinity cannot be infinite') { +ValidNumber[1.0 / 0.0] }

    assert_raises(BCDD::Contract::Error, '"1" must be numeric') { !ValidNumber['1'] }
    assert_raises(BCDD::Contract::Error, 'NaN cannot be nan') { !ValidNumber[0.0 / 0.0] }
    assert_raises(BCDD::Contract::Error, 'Infinity cannot be infinite') { !ValidNumber[1.0 / 0.0] }

    assert_raises(BCDD::Contract::Error, '"1" must be numeric') { ValidNumber['1'].value_or_err! }
    assert_raises(BCDD::Contract::Error, 'NaN cannot be nan') { ValidNumber[0.0 / 0.0].value_or_err! }
    assert_raises(BCDD::Contract::Error, 'Infinity cannot be infinite') { ValidNumber[1.0 / 0.0].value_or_err! }
  end

  test '.to_proc' do
    checkings = [1, 1r, 1.0, '1', 0.0 / 0.0, 1.0 / 0.0].map(&ValidNumber)

    checkings.each do |validation|
      assert_instance_of(BCDD::Contract::Unit::Checking, validation)
    end
  end

  test 'a valid checking' do
    checking = ValidNumber[1]

    assert_equal(1, checking.value)

    assert_predicate checking, :valid?
    refute_predicate checking, :invalid?
    refute_predicate checking, :errors?

    assert_equal([], checking.errors)
    assert_equal('', checking.errors_message)
  end

  test 'an invalid checking' do
    checking = ValidNumber['1']

    assert_equal('1', checking.value)

    refute_predicate checking, :valid?
    assert_predicate checking, :invalid?
    assert_predicate checking, :errors?

    assert_equal(['"1" must be numeric'], checking.errors)
    assert_equal('"1" must be numeric', checking.errors_message)
  end

  test 'an instance checker' do
    str_checker = BCDD::Contract::Unit[String]

    assert_instance_of(Module, str_checker)

    assert_operator str_checker, :===, '1'
    refute_operator str_checker, :===, 1

    err = assert_raises(BCDD::Contract::Error) { +str_checker[1] }

    assert_equal('1 must be a String', err.message)

    valid_checking = str_checker['2']

    assert_equal('2', valid_checking.value)

    assert_predicate valid_checking, :valid?
    refute_predicate valid_checking, :invalid?
    refute_predicate valid_checking, :errors?

    assert_equal([], valid_checking.errors)
    assert_equal('', valid_checking.errors_message)

    invalid_checking = str_checker[2]

    assert_equal(2, invalid_checking.value)

    refute_predicate invalid_checking, :valid?
    assert_predicate invalid_checking, :invalid?
    assert_predicate invalid_checking, :errors?

    assert_equal(['2 must be a String'], invalid_checking.errors)
    assert_equal('2 must be a String', invalid_checking.errors_message)
  end
end
