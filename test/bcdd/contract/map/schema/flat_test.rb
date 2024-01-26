# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::MapSchemaFlatTest < Minitest::Test
  NumberTypes = BCDD::Contract.schema(int: BCDD::Contract[Integer], float: BCDD::Contract[Float])

  test 'items are missing' do
    input = {}

    checking = NumberTypes[input]

    assert_same input, checking.value

    assert_predicate checking, :invalid?
    refute_predicate checking, :valid?

    refute_empty checking.errors
    assert_instance_of Hash, checking.errors

    assert_equal ['nil must be a Integer'], checking.errors[:int]
    assert_equal ['nil must be a Float'], checking.errors[:float]

    expected_error = '(int: nil must be a Integer; float: nil must be a Float)'

    assert_equal(expected_error, checking.errors_message)

    assert_raises(BCDD::Contract::Error, expected_error) { checking.raise_validation_errors! }

    assert_raises(BCDD::Contract::Error, expected_error) { checking.value_or_raise_validation_errors! }
    assert_raises(BCDD::Contract::Error, expected_error) { checking.value! }
    assert_raises(BCDD::Contract::Error, expected_error) { checking.assert! }

    assert_raises(BCDD::Contract::Error, expected_error) { +checking }
    assert_raises(BCDD::Contract::Error, expected_error) { !checking }
  end

  test 'valid schema' do
    input = { int: 1, float: 1.0 }

    checking = NumberTypes[input]

    assert_same input, checking.value

    assert_predicate checking, :valid?

    assert_empty checking.errors
    assert_instance_of Hash, checking.errors

    assert_equal('', checking.errors_message)
  end

  test 'invalid schema' do
    input1 = { int: 1, float: '1.0' }
    input2 = { int: '1', float: 1.0 }
    input3 = { int: '1', float: '1.0' }

    checking1 = NumberTypes[input1]
    checking2 = NumberTypes[input2]
    checking3 = NumberTypes[input3]

    assert_equal({ float: ['"1.0" must be a Float'] }, checking1.errors)
    assert_equal({ int: ['"1" must be a Integer'] }, checking2.errors)
    assert_equal({ int: ['"1" must be a Integer'], float: ['"1.0" must be a Float'] }, checking3.errors)
  end
end
