# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::DataRegisteredTest < Minitest::Test
  contract.register!(:error_by_attribute, {
    type: Hash,
    pairs: {
      key: { type: Symbol },
      value: { type: String, allow_empty: false }
    }
  })

  contract.register!(:person_params, {
    type: Hash,
    schema: {
      name: { type: String, allow_empty: false },
      age: { type: Integer }
    }
  })

  contract.register!(:list_of_strings, {
    type: [::Array, ::Set],
    schema: { type: String },
    allow_nil: true,
    allow_empty: true
  })

  test 'the inspect outputs' do
    error_by_attribute = <<~LISP
      (((type Hash) & (allow_empty false)) (pairs {
        key: (type Symbol),
        value: ((type String) & (allow_empty false))
      }))
    LISP

    assert_inspect(contract.with(error_by_attribute: true), error_by_attribute)

    person_params = <<~LISP
      (((type Hash) & (allow_empty false)) {
        name: ((type String) & (allow_empty false)),
        age: (type Integer)
      })
    LISP

    assert_inspect(contract.with(person_params: true), person_params)

    assert_inspect(
      contract.with(list_of_strings: true),
      '((((type Array) | (type Set)) | (allow_nil true)) [(type String)])'
    )
  end

  def contract
    BCDD::Contract
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
