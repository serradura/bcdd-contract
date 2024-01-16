# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::MapSchemaNestedTest < Minitest::Test
  MiscTypes = BCDD::Contract.schema(
    int: Integer,
    float: BCDD::Contract[Float],
    enum: { array: BCDD::Contract[Array], hash: Hash },
    to_sym: { sym: Symbol, str: BCDD::Contract[String] }
  )

  test 'items are missing' do
    input = {}

    checking = MiscTypes[input]

    assert_same input, checking.value

    assert_predicate checking, :invalid?
    refute_predicate checking, :valid?

    refute_empty checking.errors
    assert_instance_of Hash, checking.errors

    assert_equal ['is missing'], checking.errors[:int]
    assert_equal ['is missing'], checking.errors[:float]
    assert_equal ['is missing'], checking.errors[:to_sym]
    assert_equal ['is missing'], checking.errors[:enum]

    expected_error = '(int: is missing; float: is missing; enum: is missing; to_sym: is missing)'

    assert_equal(expected_error, checking.errors_message)

    assert_raises(BCDD::Contract::Error, expected_error) { checking.raise_validation_errors! }

    assert_raises(BCDD::Contract::Error, expected_error) { checking.value_or_raise_validation_errors! }
    assert_raises(BCDD::Contract::Error, expected_error) { checking.value! }
    assert_raises(BCDD::Contract::Error, expected_error) { checking.assert! }

    assert_raises(BCDD::Contract::Error, expected_error) { +checking }
    assert_raises(BCDD::Contract::Error, expected_error) { !checking }
  end

  test 'valid schema' do
    input = { int: 1, float: 1.0, to_sym: { sym: :sym, str: 'str' }, enum: { array: [], hash: {} } }

    checking = MiscTypes[input]

    assert_same input, checking.value

    assert_predicate checking, :valid?

    assert_empty checking.errors
    assert_instance_of Hash, checking.errors
  end

  test 'invalid schema' do
    input1 = { int: '1', float: '1.0', to_sym: nil, enum: 1 }
    input2 = { int: 1, float: 1.0, to_sym: { str: 1 }, enum: { array: 1 } }
    input3 = { int: '1', float: 1.0, to_sym: { str: 'str', sym: :sym }, enum: { array: [], hash: 1 } }

    checking1 = MiscTypes[input1]
    checking2 = MiscTypes[input2]
    checking3 = MiscTypes[input3]

    assert_equal(
      {
        int: ['"1" must be a Integer'],
        float: ['"1.0" must be a Float'],
        to_sym: ['is missing'],
        enum: ['must be a Hash']
      },
      checking1.errors
    )

    assert_equal(
      '(int: "1" must be a Integer; float: "1.0" must be a Float; enum: must be a Hash; to_sym: is missing)',
      checking1.errors_message
    )

    assert_equal(
      {
        to_sym: { sym: ['is missing'], str: ['1 must be a String'] },
        enum: { array: ['1 must be a Array'], hash: ['is missing'] }
      },
      checking2.errors
    )

    assert_equal(
      '(enum: (array: 1 must be a Array; hash: is missing); to_sym: (sym: is missing; str: 1 must be a String))',
      checking2.errors_message
    )

    assert_equal(
      {
        int: ['"1" must be a Integer'],
        enum: { hash: ['1 must be a Hash'] }
      },
      checking3.errors
    )

    assert_equal(
      '(int: "1" must be a Integer; enum: (hash: 1 must be a Hash))',
      checking3.errors_message
    )
  end
end
