# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::MapPairsFlatTest < Minitest::Test
  SymbolAndString = BCDD::Contract.pairs(Symbol => String)

  test 'value is missing' do
    input = nil

    checking = SymbolAndString[input]

    assert_same input, checking.value
    assert_predicate checking, :invalid?
    assert_equal ['nil must be a Hash'], checking.errors

    expected_error = '(nil must be a Hash)'

    assert_equal(expected_error, checking.errors_message)

    assert_raises(BCDD::Contract::Error, expected_error) { checking.raise_validation_errors! }

    assert_raises(BCDD::Contract::Error, expected_error) { checking.value_or_raise_validation_errors! }
    assert_raises(BCDD::Contract::Error, expected_error) { checking.value! }
    assert_raises(BCDD::Contract::Error, expected_error) { checking.assert! }

    assert_raises(BCDD::Contract::Error, expected_error) { +checking }
    assert_raises(BCDD::Contract::Error, expected_error) { !checking }
  end

  test 'value is empty' do
    input = {}

    checking = SymbolAndString[input]

    assert_same input, checking.value
    assert_predicate checking, :invalid?
    assert_equal ['is empty'], checking.errors

    assert_equal '(is empty)', checking.errors_message
  end

  test 'value is not a Hash' do
    input = 1

    checking = SymbolAndString[input]

    assert_same input, checking.value
    assert_predicate checking, :invalid?
    assert_equal ['1 must be a Hash'], checking.errors

    assert_equal '(1 must be a Hash)', checking.errors_message
  end

  test 'some keys are invalid' do
    input = { 1 => 'one', two: 'two', 3.0 => 'three' }

    checking = SymbolAndString[input]

    assert_same input, checking.value
    assert_predicate checking, :invalid?

    assert_equal(
      ['key: 1 must be a Symbol', 'key: 3.0 must be a Symbol'],
      checking.errors
    )

    assert_equal '(key: 1 must be a Symbol); (key: 3.0 must be a Symbol)', checking.errors_message
  end

  test 'some values are invalid' do
    input = { one: 'one', two: 2, three: 3.0 }

    checking = SymbolAndString[input]

    assert_same input, checking.value
    assert_predicate checking, :invalid?

    assert_equal(
      ['two: 2 must be a String', 'three: 3.0 must be a String'],
      checking.errors
    )

    assert_equal '(two: 2 must be a String); (three: 3.0 must be a String)', checking.errors_message
  end

  test 'some key and some value are invalid' do
    input = { 1 => 'one', two: 2 }

    checking = SymbolAndString[input]

    assert_same input, checking.value
    assert_predicate checking, :invalid?

    assert_equal(
      ['key: 1 must be a Symbol', 'two: 2 must be a String'],
      checking.errors
    )

    assert_equal(
      '(key: 1 must be a Symbol); (two: 2 must be a String)',
      checking.errors_message
    )
  end

  PairsAndSchema = BCDD::Contract.pairs(
    BCDD::Contract[Symbol] => BCDD::Contract.schema(
      str: BCDD::Contract[String],
      enum: { array: BCDD::Contract[Array], hash: BCDD::Contract[Hash] }
    )
  )

  test 'with valid schema' do
    input = { one: { str: 'one', enum: { array: [], hash: {} } } }

    checking = PairsAndSchema[input]

    assert_same input, checking.value
    assert_predicate checking, :valid?
    assert_empty checking.errors

    assert_equal('', checking.errors_message)
  end

  test 'with invalid schema' do
    input = { one: { str: 1, enum: { array: [], hash: 1 } } }

    checking = PairsAndSchema[input]

    assert_same input, checking.value
    assert_predicate checking, :invalid?

    assert_equal(
      ['one: (str: 1 must be a String; enum: (hash: 1 must be a Hash))'],
      checking.errors
    )

    assert_equal(
      '(one: (str: 1 must be a String; enum: (hash: 1 must be a Hash)))',
      checking.errors_message
    )
  end
end
