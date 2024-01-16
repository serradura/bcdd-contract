# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::MapPairsNestedTest < Minitest::Test
  NumberAndString = BCDD::Contract.pairs(BCDD::Contract[Numeric] => BCDD::Contract[String])

  SymbolAndPairs = BCDD::Contract.pairs(Symbol => NumberAndString)

  test 'values not a hash or is empty' do
    input = { one: 1, two: {}, three: nil }

    checking = SymbolAndPairs[input]

    assert_same input, checking.value
    assert_predicate checking, :invalid?

    assert_equal(
      ['one: (1 must be a Hash)', 'two: (is empty)', 'three: (nil must be a Hash)'],
      checking.errors
    )

    assert_equal(
      '(one: (1 must be a Hash)); (two: (is empty)); (three: (nil must be a Hash))',
      checking.errors_message
    )
  end

  test 'some keys are invalid' do
    input = { 1 => { 1 => 'one', 1.0 => 'um' }, two: { 2 => 'two', 2.0 => 'dois' } }

    checking = SymbolAndPairs[input]

    assert_same input, checking.value
    assert_predicate checking, :invalid?

    assert_equal(
      ['key: 1 must be a Symbol'],
      checking.errors
    )

    assert_equal '(key: 1 must be a Symbol)', checking.errors_message
  end

  test 'some key and some value are invalid' do
    input = { one: { 1 => 'one', '1.0' => 'um' }, two: { 2 => :two, '2.0' => 'dois' } }

    checking = SymbolAndPairs[input]

    assert_same input, checking.value
    assert_predicate checking, :invalid?

    assert_equal(
      ['one: (key: "1.0" must be a Numeric)', 'two: (2: :two must be a String); (key: "2.0" must be a Numeric)'],
      checking.errors
    )

    assert_equal(
      '(one: (key: "1.0" must be a Numeric)); (two: (2: :two must be a String); (key: "2.0" must be a Numeric))',
      checking.errors_message
    )
  end
end
