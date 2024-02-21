# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::DataHashPairsTest < Minitest::Test
  ErrorByAttribute = contract.with(
    type: Hash,
    pairs: {
      key: { type: Symbol },
      value: { type: String, allow_empty: false }
    }
  )

  ErrorsByAttribute = contract.with(
    type: Hash,
    allow_empty: false,
    pairs: {
      key: { type: Symbol },
      value: { type: Array, allow_empty: false, schema: { type: String, allow_empty: false } }
    }
  )

  test 'the inspect outputs' do
    error_by_attribute = <<~LISP
      (((type Hash) & (allow_empty false)) (pairs {
        key: (type Symbol),
        value: ((type String) & (allow_empty false))
      }))
    LISP

    assert_inspect(ErrorByAttribute, error_by_attribute)

    errors_by_attribute = <<~LISP
      (((type Hash) & (allow_empty false)) (pairs {
        key: (type Symbol),
        value: (
          ((type Array) & (allow_empty false)) [
            ((type String) & (allow_empty false))
          ]
        )
      }))
    LISP

    assert_inspect(ErrorsByAttribute, errors_by_attribute)
  end

  test 'the contract clauses' do
    error_by_attribute = {
      type: [Hash],
      allow_empty: [false],
      pairs: {
        key: { type: [Symbol] },
        value: { type: [String], allow_empty: [false] }
      }
    }

    assert_equal(error_by_attribute, ErrorByAttribute.clauses)

    errors_by_attribute = {
      type: [Hash],
      allow_empty: [false],
      pairs: {
        key: { type: [Symbol] },
        value: {
          type: [Array],
          allow_empty: [false],
          schema: { type: [String], allow_empty: [false] }
        }
      }
    }

    assert_equal(errors_by_attribute, ErrorsByAttribute.clauses)
  end

  test 'the value checking' do
    error_by_attribute1 = ErrorByAttribute.new(nil)
    error_by_attribute2 = ErrorByAttribute.new({})
    error_by_attribute3 = ErrorByAttribute.new(one: 1, 'two' => '2', 'three' => '')
    error_by_attribute4 = ErrorByAttribute.new(one: '1', two: '2', three: '3')

    assert_equal({ value: nil, violations: { type: [Hash] } }, error_by_attribute1.to_h)
    assert_equal({ value: {}, violations: { allow_empty: [false] } }, error_by_attribute2.to_h)
    assert_equal(
      {
        value: { one: 1, 'two' => '2', 'three' => '' },
        violations: {
          :one => { value: { value: 1, violations: { type: [String] } } },
          'two' => { key: { value: 'two', violations: { type: [Symbol] } } },
          'three' => {
            key: { value: 'three', violations: { type: [Symbol] } },
            value: { value: '', violations: { allow_empty: [false] } }
          }
        }
      },
      error_by_attribute3.to_h
    )
    assert_equal({ value: { one: '1', two: '2', three: '3' }, violations: {} }, error_by_attribute4.to_h)

    assert_equal({ type: [Hash] }, error_by_attribute1.violations)
    assert_equal({ allow_empty: [false] }, error_by_attribute2.violations)
    assert_equal(
      {
        :one => { value: { type: [String] } },
        'two' => { key: { type: [Symbol] } },
        'three' => {
          key: { type: [Symbol] },
          value: { allow_empty: [false] }
        }
      },
      error_by_attribute3.violations
    )
    assert_equal({}, error_by_attribute4.violations)

    # ---

    errors_by_attribute1 = ErrorsByAttribute.new(nil)
    errors_by_attribute2 = ErrorsByAttribute.new({})
    errors_by_attribute3 = ErrorsByAttribute.new(one: 1, 'two' => %w[2], 'three' => [], four: [4])
    errors_by_attribute4 = ErrorsByAttribute.new(one: %w[1], two: %w[2], three: %w[3])

    assert_equal({ value: nil, violations: { type: [Hash] } }, errors_by_attribute1.to_h)
    assert_equal({ value: {}, violations: { allow_empty: [false] } }, errors_by_attribute2.to_h)
    assert_equal(
      {
        value: { :one => 1, 'two' => %w[2], 'three' => [], :four => [4] },
        violations: {
          :one => { value: { value: 1, violations: { type: [Array] } } },
          'two' => { key: { value: 'two', violations: { type: [Symbol] } } },
          'three' => {
            key: { value: 'three', violations: { type: [Symbol] } },
            value: { value: [], violations: { allow_empty: [false] } }
          },
          :four => {
            value: {
              value: [4],
              violations: { 0 => { value: 4, violations: { type: [String] } } }
            }
          }
        }
      },
      errors_by_attribute3.to_h
    )
    assert_equal({ value: { one: %w[1], two: %w[2], three: %w[3] }, violations: {} }, errors_by_attribute4.to_h)

    assert_equal({ type: [Hash] }, errors_by_attribute1.violations)
    assert_equal({ allow_empty: [false] }, errors_by_attribute2.violations)
    assert_equal(
      {
        :one => { value: { type: [Array] } },
        'two' => { key: { type: [Symbol] } },
        'three' => {
          key: { type: [Symbol] },
          value: { allow_empty: [false] }
        },
        :four => { value: { 0 => { type: [String] } } }
      },
      errors_by_attribute3.violations
    )
    assert_equal({}, errors_by_attribute4.violations)
  end

  def assert_inspect(contract, heredoc)
    expected = heredoc
                .gsub(/\s+/, ' ')
                .strip
                .gsub('{ ', '{')
                .gsub(' }', '}')
                .gsub('[ ', '[')
                .gsub(' ]', ']')
                .gsub('( ', '(')
                .gsub(' )', ')')

    assert_equal(expected, contract.inspect)
  end
end
