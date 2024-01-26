# frozen_string_literal: true

require 'test_helper'

class BCDD::ContractTest < Minitest::Test
  ListOfStrings = BCDD::Contract([String])

  test 'list of strings' do
    assert_operator ListOfStrings, :===, %w[a b c]
    assert_operator ListOfStrings, :===, Set['a', 'b', 'c']

    refute_operator ListOfStrings, :===, ['a', 1, 'c']
    refute_operator ListOfStrings, :===, Set['a', 1, 'c']
  end

  SetOfSymbols = BCDD::Contract(Set[Symbol])

  test 'set of symbols' do
    assert_operator SetOfSymbols, :===, %i[a b c]
    assert_operator SetOfSymbols, :===, Set[:a, :b, :c]

    refute_operator SetOfSymbols, :===, [:a, 1, :c]
    refute_operator SetOfSymbols, :===, Set[:a, 1, :c]
  end

  test 'invalid list checker creation' do
    assert_raises(ArgumentError, 'must be one contract checker') { BCDD::Contract([String, Symbol]) }
  end

  MiscOfCheckers = BCDD::Contract([{
    a: Integer,
    b: String,
    c: {
      d: [Integer],
      e: { f: [String] }
    }
  }])

  test 'misc of checkers' do
    assert_operator MiscOfCheckers, :===, [{
      a: 1,
      b: '2',
      c: {
        d: [3, 4],
        e: {
          f: ['4']
        }
      }
    }]

    data = [
      {
        a: 1,
        b: '2',
        c: {
          d: ['3'],
          e: {
            f: [4]
          }
        }
      },
      {},
      nil,
      {
        a: '1'
      }
    ]

    refute_operator MiscOfCheckers, :===, data

    assert_equal(
      [
        '0: (c: (d: 0: "3" must be a Integer; e: (f: 0: 4 must be a String)))',
        '1: (a: nil must be a Integer; b: nil must be a String; c: (nil: must be a Hash))',
        '2: (nil: must be a Hash)',
        '3: (a: "1" must be a Integer; b: nil must be a String; c: (nil: must be a Hash))'
      ],
      MiscOfCheckers[data].errors
    )
  end
end
