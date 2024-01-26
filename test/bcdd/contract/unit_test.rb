# frozen_string_literal: true

require 'test_helper'

module BCDD::Contract
  class UnitTest < Minitest::Test
    cannot_be_inf = ->(val, err) { err << '%p cannot be infinite' if val.respond_to?(:infinite?) && val.infinite? }
    cannot_be_nan = ->(val, err) { err << '%p cannot be nan' if val.respond_to?(:nan?) && val.nan? }

    CannotBeInfinity = ::BCDD::Contract.unit(cannot_be_inf)
    CannotBeNaN      = ::BCDD::Contract.unit(cannot_be_nan)
    IsNumeric        = ::BCDD::Contract.unit(Numeric)

    ValidNumber = (IsNumeric & CannotBeNaN & CannotBeInfinity) | nil

    test 'the checking: argument validation' do
      err1 = assert_raises(ArgumentError) { ::BCDD::Contract.unit(Object.new) }
      err2 = assert_raises(ArgumentError) { ::BCDD::Contract.unit(proc {}) }
      err3 = assert_raises(ArgumentError) { ::BCDD::Contract.unit(-> {}) }

      assert(err1.message.end_with?('must be a class, module or lambda'))
      assert_equal('must be a lambda', err2.message)
      assert_equal('must have two arguments (value, errors)', err3.message)
    end

    test 'that is a module' do
      assert_instance_of Module, ValidNumber
      assert_kind_of Unit::Checker, ValidNumber

      assert_equal('BCDD::Contract::UnitTest::ValidNumber', ValidNumber.name)

      assert_equal('BCDD::Contract::UnitTest::ValidNumber', ValidNumber.inspect)
    end

    test '.===' do
      assert ValidNumber === 1
      assert ValidNumber === 1r
      assert ValidNumber === 1.0

      assert_operator ValidNumber, :===, nil

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

      assert_equal(1, ValidNumber[1].value_or_raise_validation_errors!)
      assert_equal(1r, ValidNumber[1r].value_or_raise_validation_errors!)
      assert_in_delta(1.0, ValidNumber[1.0].value_or_raise_validation_errors!)

      assert_raises(BCDD::Contract::Error, '"1" must be a Numeric OR "1" must be a NilClass') do
        ValidNumber['1'].value_or_raise_validation_errors!
      end
      assert_raises(BCDD::Contract::Error, 'NaN cannot be nan') do
        ValidNumber[0.0 / 0.0].value_or_raise_validation_errors!
      end
      assert_raises(BCDD::Contract::Error, 'Infinity cannot be infinite') do
        ValidNumber[1.0 / 0.0].value_or_raise_validation_errors!
      end

      assert_raises(BCDD::Contract::Error, '"1" must be a Numeric') { ValidNumber['1'].value! }
      assert_raises(BCDD::Contract::Error, 'NaN cannot be nan') { ValidNumber[0.0 / 0.0].value! }
      assert_raises(BCDD::Contract::Error, 'Infinity cannot be infinite') { ValidNumber[1.0 / 0.0].value! }

      assert_raises(BCDD::Contract::Error, '"1" must be a Numeric') { +ValidNumber['1'] }
      assert_raises(BCDD::Contract::Error, 'NaN cannot be nan') { +ValidNumber[0.0 / 0.0] }
      assert_raises(BCDD::Contract::Error, 'Infinity cannot be infinite') { +ValidNumber[1.0 / 0.0] }

      assert_raises(BCDD::Contract::Error, '"1" must be a Numeric') { !ValidNumber['1'] }
      assert_raises(BCDD::Contract::Error, 'NaN cannot be nan') { !ValidNumber[0.0 / 0.0] }
      assert_raises(BCDD::Contract::Error, 'Infinity cannot be infinite') { !ValidNumber[1.0 / 0.0] }

      assert_raises(BCDD::Contract::Error, '"1" must be a Numeric') { ValidNumber['1'].assert! }
      assert_raises(BCDD::Contract::Error, 'NaN cannot be nan') { ValidNumber[0.0 / 0.0].assert! }
      assert_raises(BCDD::Contract::Error, 'Infinity cannot be infinite') { ValidNumber[1.0 / 0.0].assert! }
    end

    test '.to_proc' do
      checkings = [1, 1r, 1.0, '1', 0.0 / 0.0, 1.0 / 0.0].map(&ValidNumber)

      checkings.each do |validation|
        assert_instance_of(Unit::Checking, validation)
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

      assert_equal(['"1" must be a Numeric OR "1" must be a NilClass'], checking.errors)
      assert_equal('"1" must be a Numeric OR "1" must be a NilClass', checking.errors_message)
    end

    test 'an instance checker' do
      str_checker = ::BCDD::Contract.unit(String)

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
end
