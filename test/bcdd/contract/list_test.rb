# frozen_string_literal: true

require 'test_helper'

module BCDD::Contract
  class ListTest < Minitest::Test
    test 'value is missing' do
      input = nil

      checking = BCDD::Contract.list(Symbol)[input]

      assert_same input, checking.value
      assert_predicate checking, :invalid?
      assert_equal ['nil must be a Set | Array'], checking.errors

      expected_error = '(nil must be a Set | Array)'

      assert_equal(expected_error, checking.errors_message)

      assert_raises(Error, expected_error) { checking.raise_validation_errors! }

      assert_raises(Error, expected_error) { checking.value_or_raise_validation_errors! }
      assert_raises(Error, expected_error) { checking.value! }
      assert_raises(Error, expected_error) { checking.assert! }

      assert_raises(Error, expected_error) { +checking }
      assert_raises(Error, expected_error) { !checking }
    end

    test 'value is empty' do
      input = []

      checking = BCDD::Contract.list(Symbol)[input]

      assert_same input, checking.value
      assert_predicate checking, :invalid?
      assert_equal ['is empty'], checking.errors

      assert_equal '(is empty)', checking.errors_message
    end

    test 'value is not a Set | Array' do
      input = 1

      checking = BCDD::Contract.list(Symbol)[input]

      assert_same input, checking.value
      assert_predicate checking, :invalid?
      assert_equal ['1 must be a Set | Array'], checking.errors

      assert_equal '(1 must be a Set | Array)', checking.errors_message
    end

    test 'some values are invalid' do
      input = [:one, 2, 'three']

      # ---

      checking1 = BCDD::Contract.list(Symbol)[input]

      assert_same input, checking1.value
      assert_predicate checking1, :invalid?
      assert_equal ['1: 2 must be a Symbol', '2: "three" must be a Symbol'], checking1.errors

      assert_equal '(1: 2 must be a Symbol; 2: "three" must be a Symbol)', checking1.errors_message

      # ---

      checking2 = BCDD::Contract.list([Symbol])[input]

      assert_same input, checking2.value
      assert_predicate checking2, :invalid?
      assert_equal ['1: 2 must be a Symbol', '2: "three" must be a Symbol'], checking2.errors

      assert_equal '(1: 2 must be a Symbol; 2: "three" must be a Symbol)', checking2.errors_message
    end

    test 'values are valid' do
      input = %i[one two three]

      # ---

      checking1 = BCDD::Contract.list(Symbol)[input]

      assert_same input, checking1.value
      assert_predicate checking1, :valid?
      assert_empty checking1.errors

      assert_equal '', checking1.errors_message

      # ---

      checking2 = BCDD::Contract.list([Symbol])[input]

      assert_same input, checking2.value
      assert_predicate checking2, :valid?
      assert_empty checking2.errors

      assert_equal '', checking2.errors_message
    end
  end
end
