# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::DataListSchemaTest < Minitest::Test
  ListOfString = contract.with(
    type: [::Array, ::Set],
    schema: { type: String },
    allow_nil: true,
    allow_empty: true
  )

  FilledArrayOfString = contract.with(
    type: Array,
    schema: { type: String }
  )

  ListOfArrayOfString = contract.with(
    type: [::Array, ::Set],
    schema: {
      type: Array,
      schema: { type: String },
      allow_empty: true
    },
    allow_empty: true
  )

  test 'the objects' do
    assert_equal '((((type Array) | (type Set)) | (allow_nil true)) [(type String)])', ListOfString.inspect

    assert_equal({ type: [Array, Set], allow_nil: [true], schema: { type: [String] } }, ListOfString.clauses)

    # ---

    assert_equal '(((type Array) & (allow_empty false)) [(type String)])', FilledArrayOfString.inspect

    assert_equal({ type: [Array], allow_empty: [false], schema: { type: [String] } }, FilledArrayOfString.clauses)

    # ---

    assert_equal '(((type Array) | (type Set)) [((type Array) [(type String)])])', ListOfArrayOfString.inspect

    assert_equal(
      { type: [Array, Set], schema: { type: [Array], schema: { type: [String] } } },
      ListOfArrayOfString.clauses
    )
  end

  test 'the value checking' do
    set = Set.new

    checking1 = ListOfString.new(nil)
    checking2 = ListOfString.new(set)
    checking3 = ListOfString.new([])
    checking4 = ListOfString.new([1, 'string', 2])

    assert_equal({ value: nil, violations: {} }, checking1.to_h)
    assert_equal({ value: set, violations: {} }, checking2.to_h)
    assert_equal({ value: [], violations: {} }, checking3.to_h)

    assert_equal({
      value: [1, 'string', 2],
      violations: {
        0 => { value: 1, violations: { type: [String] } },
        2 => { value: 2, violations: { type: [String] } }
      }
    }, checking4.to_h)

    assert_equal({}, checking1.violations)
    assert_equal({}, checking2.violations)
    assert_equal({}, checking3.violations)
    assert_equal({ 0 => { type: [String] }, 2 => { type: [String] } }, checking4.violations)

    # ---

    checking5 = FilledArrayOfString.new(nil)
    checking6 = FilledArrayOfString.new(set)
    checking7 = FilledArrayOfString.new([])
    checking8 = FilledArrayOfString.new([1, 'string', 2])

    assert_equal({ value: nil, violations: { type: [Array] } }, checking5.to_h)
    assert_equal({ value: set, violations: { type: [Array] } }, checking6.to_h)
    assert_equal({ value: [], violations: { allow_empty: [false] } }, checking7.to_h)
    assert_equal({
      value: [1, 'string', 2],
      violations: {
        0 => { value: 1, violations: { type: [String] } },
        2 => { value: 2, violations: { type: [String] } }
      }
    }, checking8.to_h)

    assert_equal({ type: [Array] }, checking5.violations)
    assert_equal({ type: [Array] }, checking6.violations)
    assert_equal({ allow_empty: [false] }, checking7.violations)
    assert_equal({ 0 => { type: [String] }, 2 => { type: [String] } }, checking8.violations)

    # ---

    checking9 = ListOfArrayOfString.new(set)
    checking10 = ListOfArrayOfString.new([])
    checking11 = ListOfArrayOfString.new([%w[1 2 3], ['4']])
    checking12 = ListOfArrayOfString.new([1, 'string', 2])
    checking13 = ListOfArrayOfString.new([[1, 'string', 2], 3])

    assert_equal({ value: set, violations: {} }, checking9.to_h)
    assert_equal({ value: [], violations: {} }, checking10.to_h)
    assert_equal({ value: [%w[1 2 3], ['4']], violations: {} }, checking11.to_h)

    assert_equal(
      {
        value: [1, 'string', 2],
        violations: {
          0 => { value: 1, violations: { type: [Array] } },
          1 => { value: 'string', violations: { type: [Array] } },
          2 => { value: 2, violations: { type: [Array] } }
        }
      },
      checking12.to_h
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
      checking13.to_h
    )

    assert_equal({}, checking9.violations)
    assert_equal({}, checking10.violations)
    assert_equal({}, checking11.violations)

    assert_equal(
      { 0 => { type: [Array] }, 1 => { type: [Array] }, 2 => { type: [Array] } },
      checking12.violations
    )

    assert_equal(
      {
        0 => { 0 => { type: [String] }, 2 => { type: [String] } },
        1 => { type: [Array] }
      },
      checking13.violations
    )
  end
end
