# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::RequirementsDataStructureListTest < Minitest::Test
  ListOfString = contract.with(type: [::Array, ::Set], schema: { type: String })

  FilledArrayOfString = contract.with(type: Array, filled: true, schema: { type: String })

  ListOfArrayOfString = contract.with(type: [::Array, ::Set], schema: { type: Array, schema: { type: String } })

  test 'the objects' do
    assert_equal '(((type Array) | (type Set)) [(type String)])', ListOfString.inspect

    assert_equal({ data: { type: [Array, Set] }, schema: { type: [String] } }, ListOfString.clauses)

    assert_equal({ type: [Array, Set] }, ListOfString.data.clauses)

    assert ListOfString.data.clause?(:type)
    assert ListOfString.data.clause?(:type, Array)
    assert ListOfString.data.clause?(:type, Set)

    assert_equal({ type: [String] }, ListOfString.schema.clauses)

    assert ListOfString.schema.clause?(:type)
    assert ListOfString.schema.clause?(:type, String)

    # ---

    assert_equal '(((type Array) & (filled true)) [(type String)])', FilledArrayOfString.inspect

    assert_equal({ data: { type: [Array], filled: [true] }, schema: { type: [String] } }, FilledArrayOfString.clauses)

    assert_equal({ type: [Array], filled: [true] }, FilledArrayOfString.data.clauses)

    assert FilledArrayOfString.data.clause?(:type)
    assert FilledArrayOfString.data.clause?(:type, Array)
    refute FilledArrayOfString.data.clause?(:type, Set)

    assert FilledArrayOfString.data.clause?(:filled)
    assert FilledArrayOfString.data.clause?(:filled, true)

    assert_equal({ type: [String] }, FilledArrayOfString.schema.clauses)

    assert FilledArrayOfString.schema.clause?(:type)
    assert FilledArrayOfString.schema.clause?(:type, String)

    # ---

    assert_equal '(((type Array) | (type Set)) [((type Array) [(type String)])])', ListOfArrayOfString.inspect

    assert_equal(
      { data: { type: [Array, Set] }, schema: { data: { type: [Array] }, schema: { type: [String] } } },
      ListOfArrayOfString.clauses
    )

    assert_equal({ type: [Array, Set] }, ListOfArrayOfString.data.clauses)

    assert ListOfArrayOfString.data.clause?(:type)
    assert ListOfArrayOfString.data.clause?(:type, Array)
    assert ListOfArrayOfString.data.clause?(:type, Set)

    assert_equal({ data: { type: [Array] }, schema: { type: [String] } }, ListOfArrayOfString.schema.clauses)
  end

  test 'the value checking' do
    set = Set.new

    checking1 = ListOfString.new(set)
    checking2 = ListOfString.new([])
    checking3 = ListOfString.new([1, 'string', 2])

    assert_equal({ value: set, violations: {} }, checking1.to_h)
    assert_equal({ value: [], violations: {} }, checking2.to_h)

    assert_equal({
      value: [1, 'string', 2],
      violations: {
        0 => { value: 1, violations: { type: [String] } },
        2 => { value: 2, violations: { type: [String] } }
      }
    }, checking3.to_h)

    assert_equal({}, checking1.violations)
    assert_equal({}, checking2.violations)
    assert_equal({ 0 => { type: [String] }, 2 => { type: [String] } }, checking3.violations)

    # ---

    checking4 = FilledArrayOfString.new(set)
    checking5 = FilledArrayOfString.new([])
    checking6 = FilledArrayOfString.new([1, 'string', 2])

    assert_equal({ value: set, violations: { type: [Array] } }, checking4.to_h)
    assert_equal({ value: [], violations: { filled: [true] } }, checking5.to_h)
    assert_equal({
      value: [1, 'string', 2],
      violations: {
        0 => { value: 1, violations: { type: [String] } },
        2 => { value: 2, violations: { type: [String] } }
      }
    }, checking6.to_h)

    assert_equal({ type: [Array] }, checking4.violations)
    assert_equal({ filled: [true] }, checking5.violations)
    assert_equal({ 0 => { type: [String] }, 2 => { type: [String] } }, checking6.violations)

    # ---

    checking7 = ListOfArrayOfString.new(set)
    checking8 = ListOfArrayOfString.new([])
    checking9 = ListOfArrayOfString.new([%w[1 2 3], ['4']])
    checking10 = ListOfArrayOfString.new([1, 'string', 2])
    checking11 = ListOfArrayOfString.new([[1, 'string', 2], 3])

    assert_equal({ value: set, violations: {} }, checking7.to_h)
    assert_equal({ value: [], violations: {} }, checking8.to_h)
    assert_equal({ value: [%w[1 2 3], ['4']], violations: {} }, checking9.to_h)

    assert_equal(
      {
        value: [1, 'string', 2],
        violations: {
          0 => { value: 1, violations: { type: [Array] } },
          1 => { value: 'string', violations: { type: [Array] } },
          2 => { value: 2, violations: { type: [Array] } }
        }
      },
      checking10.to_h
    )

    assert_equal(
      {
        value: [[1, 'string', 2], 3],
        violations: {
          0 => {
            value: [1, 'string', 2],
            violations: {
              0 => { value: 1, violations: { type:  [String] } },
              2 => { value: 2, violations: { type:  [String] } }
            }
          },
          1 => { value: 3, violations: { type: [Array] } }
        }
      },
      checking11.to_h
    )

    assert_equal({}, checking7.violations)
    assert_equal({}, checking8.violations)
    assert_equal({}, checking9.violations)

    assert_equal(
      { 0 => { type: [Array] }, 1 => { type: [Array] }, 2 => { type: [Array] } },
      checking10.violations
    )

    assert_equal(
      {
        0 => { 0 => { type: [String] }, 2 => { type: [String] } },
        1 => { type: [Array] }
      },
      checking11.violations
    )
  end
end
