# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::RequirementsDataStructureListTest < Minitest::Test
  ListOfString = contract.with(type: [::Array, ::Set], items: { type: String })
  FilledArrayOfString = contract.with(type: Array, filled: true, items: { type: String })

  test 'the objects' do
    assert_equal({ type: [Array, Set], _items: { type: [String] } }, ListOfString.clauses)

    assert ListOfString.clause?(:type)
    assert ListOfString.clause?(:type, Array)
    assert ListOfString.clause?(:type, Set)

    assert_equal '(((type Array) | (type Set)) [(type String)])', ListOfString.inspect

    assert_equal({ type: [String] }, ListOfString.items_clauses)

    assert ListOfString.items_clause?(:type)
    assert ListOfString.items_clause?(:type, String)

    # ---

    assert_equal({ type: [Array], filled: [true], _items: { type: [String] } }, FilledArrayOfString.clauses)

    assert FilledArrayOfString.clause?(:type)
    assert FilledArrayOfString.clause?(:type, Array)
    refute FilledArrayOfString.clause?(:type, Set)

    assert FilledArrayOfString.clause?(:filled)
    assert FilledArrayOfString.clause?(:filled, true)

    assert_equal '(((type Array) & (filled true)) [(type String)])', FilledArrayOfString.inspect

    assert_equal({ type: [String] }, FilledArrayOfString.items_clauses)

    assert FilledArrayOfString.items_clause?(:type)
    assert FilledArrayOfString.items_clause?(:type, String)
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
  end
end
