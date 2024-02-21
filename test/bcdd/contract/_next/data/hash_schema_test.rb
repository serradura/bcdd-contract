# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::DataHashSchemaTest < Minitest::Test
  PersonParams1a = contract.with(
    type: Hash,
    schema: {
      name: { type: String, allow_empty: false },
      age: { type: Integer }
    }
  )

  PersonParams1b = contract.with(
    type: Hash,
    schema: {
      name: { type: String, allow_empty: false },
      age: { type: Integer }
    },
    allow_nil: true
  )

  PersonParams1c = contract.with(
    type: Hash,
    schema: {
      name: { type: String, allow_empty: false },
      age: { type: Integer }
    },
    allow_empty: true
  )

  PersonParams1d = contract.with(
    type: Hash,
    schema: {
      name: { type: String, allow_empty: false },
      age: { type: Integer }
    },
    allow_nil: true,
    allow_empty: true
  )

  PersonParams2 = contract.with(
    type: Hash,
    schema: {
      name: { type: String },
      age: { type: Integer },
      address: {
        type: Hash,
        schema: {
          street: { type: String },
          number: { type: Integer },
          city: { type: String },
          state: { type: String },
          country: { type: String }
        }
      },
      phone_numbers: { type: Array, schema: { type: String } }
    }
  )

  PeopleParams3 = contract.with(
    type: Array,
    schema: {
      type: Hash,
      schema: {
        name: { type: String },
        age: { type: Integer },
        address: {
          type: Hash,
          schema: {
            street: { type: String },
            number: { type: Integer },
            city: { type: String },
            state: { type: String },
            country: { type: String }
          }
        },
        phone_numbers: { type: Array, schema: { type: String } }
      }
    }
  )

  test 'the inspect outputs' do
    person_params1a = <<~LISP
      (((type Hash) & (allow_empty false)) {
        name: ((type String) & (allow_empty false)),
        age: (type Integer)
      })
    LISP

    person_params1b = <<~LISP
      ((((type Hash) & (allow_empty false)) | (allow_nil true)) {
        name: ((type String) & (allow_empty false)),
        age: (type Integer)
      })
    LISP

    person_params1c = <<~LISP
      ((type Hash) {
        name: ((type String) & (allow_empty false)),
        age: (type Integer)
      })
    LISP

    person_params1d = <<~LISP
      (((type Hash) | (allow_nil true)) {
        name: ((type String) & (allow_empty false)),
        age: (type Integer)
      })
    LISP

    assert_inspect(PersonParams1a, person_params1a)
    assert_inspect(PersonParams1b, person_params1b)
    assert_inspect(PersonParams1c, person_params1c)
    assert_inspect(PersonParams1d, person_params1d)

    person_params2 = <<~LISP
      (((type Hash) & (allow_empty false)) {
        name: (type String),
        age: (type Integer),
        address: (
          ((type Hash) & (allow_empty false)) {
            street: (type String),
            number: (type Integer),
            city: (type String),
            state: (type String),
            country: (type String)
          }
        ),
        phone_numbers: (
          ((type Array) & (allow_empty false)) [
            (type String)
          ]
        )
      })
    LISP

    assert_inspect(PersonParams2, person_params2)

    people_params3 = <<~LISP
      (((type Array) & (allow_empty false)) [
        (((type Hash) & (allow_empty false)) {
          name: (type String),
          age: (type Integer),
          address: (
            ((type Hash) & (allow_empty false)) {
              street: (type String),
              number: (type Integer),
              city: (type String),
              state: (type String),
              country: (type String)
            }
          ),
          phone_numbers: (
            ((type Array) & (allow_empty false)) [
              (type String)
            ]
          )
        })
      ])
    LISP

    assert_inspect(PeopleParams3, people_params3)
  end

  test 'the contract clauses' do
    person_params1a = {
      type: [Hash],
      allow_empty: [false],
      schema: {
        name: { type: [String], allow_empty: [false] },
        age: { type: [Integer] }
      }
    }

    person_params1b = {
      type: [Hash],
      allow_empty: [false],
      allow_nil: [true],
      schema: {
        name: { type: [String], allow_empty: [false] },
        age: { type: [Integer] }
      }
    }

    person_params1c = {
      type: [Hash],
      schema: {
        name: { type: [String], allow_empty: [false] },
        age: { type: [Integer] }
      }
    }

    person_params1d = {
      type: [Hash],
      allow_nil: [true],
      schema: {
        name: { type: [String], allow_empty: [false] },
        age: { type: [Integer] }
      }
    }

    assert_equal(person_params1a, PersonParams1a.clauses)
    assert_equal(person_params1b, PersonParams1b.clauses)
    assert_equal(person_params1c, PersonParams1c.clauses)
    assert_equal(person_params1d, PersonParams1d.clauses)

    person_params2 = {
      type: [Hash],
      allow_empty: [false],
      schema: {
        name: { type: [String] },
        age: { type: [Integer] },
        address: {
          type: [Hash],
          allow_empty: [false],
          schema: {
            street: { type: [String] },
            number: { type: [Integer] },
            city: { type: [String] },
            state: { type: [String] },
            country: { type: [String] }
          }
        },
        phone_numbers: {
          type: [Array], allow_empty: [false], schema: { type: [String] }
        }
      }
    }

    assert_equal(person_params2, PersonParams2.clauses)

    people_params3 = {
      type: [Array],
      allow_empty: [false],
      schema: {
        type: [Hash],
        allow_empty: [false],
        schema: {
          name: { type: [String] },
          age: { type: [Integer] },
          address: {
            type: [Hash],
            allow_empty: [false],
            schema: {
              street: { type: [String] },
              number: { type: [Integer] },
              city: { type: [String] },
              state: { type: [String] },
              country: { type: [String] }
            }
          },
          phone_numbers: {
            type: [Array], allow_empty: [false], schema: { type: [String] }
          }
        }
      }
    }

    assert_equal(people_params3, PeopleParams3.clauses)
  end

  test 'the value checking' do
    person_params1a = PersonParams1a.new(nil)
    person_params1b = PersonParams1b.new(nil)
    person_params1c = PersonParams1c.new(nil)
    person_params1d = PersonParams1d.new(nil)

    assert_equal({ value: nil, violations: { type: [Hash] } }, person_params1a.to_h)
    assert_equal({ value: nil, violations: {} }, person_params1b.to_h)
    assert_equal({ value: nil, violations: { type: [Hash] } }, person_params1c.to_h)
    assert_equal({ value: nil, violations: {} }, person_params1d.to_h)

    assert_equal({ type: [Hash] }, person_params1a.violations)
    assert_equal({}, person_params1b.violations)
    assert_equal({ type: [Hash] }, person_params1c.violations)
    assert_equal({}, person_params1d.violations)

    person_params2 = PersonParams2.new(nil)

    assert_equal({ value: nil, violations: { type: [Hash] } }, person_params2.to_h)

    assert_equal({ type: [Hash] }, person_params2.violations)

    people_params3 = PeopleParams3.new(nil)

    assert_equal({ value: nil, violations: { type: [Array] } }, people_params3.to_h)

    assert_equal({ type: [Array] }, people_params3.violations)

    # ---

    person_params1a = PersonParams1a.new({})
    person_params1b = PersonParams1b.new({})
    person_params1c = PersonParams1c.new({})
    person_params1d = PersonParams1d.new({})

    assert_equal({ value: {}, violations: { allow_empty: [false] } }, person_params1a.to_h)
    assert_equal({ value: {}, violations: { allow_empty: [false], allow_nil: [true] } }, person_params1b.to_h)
    assert_equal({ value: {}, violations: {} }, person_params1c.to_h)
    assert_equal({ value: {}, violations: {} }, person_params1d.to_h)

    assert_equal({ allow_empty: [false] }, person_params1a.violations)
    assert_equal({ allow_empty: [false], allow_nil: [true] }, person_params1b.violations)
    assert_equal({}, person_params1c.violations)
    assert_equal({}, person_params1d.violations)

    person_params2 = PersonParams2.new({})

    assert_equal({ value: {}, violations: { allow_empty: [false] } }, person_params2.to_h)

    assert_equal({ allow_empty: [false] }, person_params2.violations)

    people_params3 = PeopleParams3.new({})

    assert_equal({ value: {}, violations: { type: [Array] } }, people_params3.to_h)

    assert_equal({ type: [Array] }, people_params3.violations)

    # --- PersonParams1a ---

    person_params1a = PersonParams1a.new(name: :John, age: 30.0)

    assert_equal(
      {
        value: { name: :John, age: 30.0 },
        violations: {
          name: { value: :John, violations: { type: [String] } },
          age: { value: 30.0, violations: { type: [Integer] } }
        }
      },
      person_params1a.to_h
    )

    assert_equal(
      {
        name: { type: [String] },
        age: { type: [Integer] }
      },
      person_params1a.violations
    )

    # --- PersonParams1b ---

    person_params1b = PersonParams1b.new(name: '', age: 30)

    assert_equal(
      {
        value: { name: '', age: 30 },
        violations: {
          name: { value: '', violations: { allow_empty: [false] } }
        }
      },
      person_params1b.to_h
    )

    assert_equal(
      { name: { allow_empty: [false] } },
      person_params1b.violations
    )

    # --- PersonParams1c ---

    person_params1c = PersonParams1c.new(name: 'John', age: '30')

    assert_equal(
      {
        value: { name: 'John', age: '30' },
        violations: {
          age: { value: '30', violations: { type: [Integer] } }
        }
      },
      person_params1c.to_h
    )

    assert_equal(
      { age: { type: [Integer] } },
      person_params1c.violations
    )

    # --- PersonParams1d ---

    person_params1d = PersonParams1d.new(name: 'John', age: 30)

    assert_equal(
      { value: { name: 'John', age: 30 }, violations: {} },
      person_params1d.to_h
    )

    assert_equal({}, person_params1d.violations)

    # --- PersonParams2 ---

    person_params2a = PersonParams2.new({ name: nil })

    assert_equal(
      {
        value: { name: nil },
        violations: {
          name: { value: nil, violations: { type: [String] } },
          age: { value: nil, violations: { type: [Integer] } },
          address: { value: nil, violations: { type: [Hash] } },
          phone_numbers: {
            value: nil, violations: { type: [Array] }
          }
        }
      },
      person_params2a.to_h
    )

    john_address = {
      street: 'Main St',
      number: 123,
      city: 'New York',
      state: 'NY',
      country: 'USA'
    }

    person_params2b = PersonParams2.new({
      name: 'John',
      age: 30,
      address: john_address,
      phone_numbers: ['123-456-7890', 123]
    })

    assert_equal(
      {
        value: { name: 'John', age: 30, address: john_address, phone_numbers: ['123-456-7890', 123] },
        violations: {
          phone_numbers: {
            value: ['123-456-7890', 123],
            violations: {
              1 => { value: 123, violations: { type: [String] } }
            }
          }
        }
      },
      person_params2b.to_h
    )

    assert_equal(
      { phone_numbers: { 1 => { type: [String] } } },
      person_params2b.violations
    )

    person_params2c = PersonParams2.new({
      name: 'John',
      age: 30,
      address: john_address,
      phone_numbers: ['123-456-7890']
    })

    assert_equal(
      { value: { name: 'John', age: 30, address: john_address, phone_numbers: ['123-456-7890'] }, violations: {} },
      person_params2c.to_h
    )

    assert_equal(
      {},
      person_params2c.violations
    )

    # --- PeopleParams3 ---

    jane_address = john_address.merge(street: nil)

    people_params3a = PeopleParams3.new([
      {
        name: 'John',
        age: 30,
        address: john_address,
        phone_numbers: [123, '123-456-7890']
      },
      {
        name: 'Jane',
        age: 25,
        address: jane_address,
        phone_numbers: ['123-456-7890']
      }
    ])

    assert_equal(
      {
        value: [
          {
            name: 'John', age: 30, address: john_address, phone_numbers: [123, '123-456-7890']
          },
          {
            name: 'Jane', age: 25, address: jane_address, phone_numbers: ['123-456-7890']
          }
        ],
        violations: {
          0 => {
            value: {
              name: 'John', age: 30, address: john_address, phone_numbers: [123, '123-456-7890']
            },
            violations: {
              phone_numbers: {
                value: [123, '123-456-7890'],
                violations: { 0 => { value: 123, violations: { type: [String] } } }
              }
            }
          },
          1 => {
            value: {
              name: 'Jane', age: 25, address: jane_address, phone_numbers: ['123-456-7890']
            },
            violations: {
              address: {
                value: jane_address,
                violations: { street: { value: nil, violations: { type: [String] } } }
              }
            }
          }
        }
      },
      people_params3a.to_h
    )

    assert_equal(
      {
        0 => { phone_numbers: { 0 => { type: [String] } } },
        1 => { address: { street: { type: [String] } } }
      },
      people_params3a.violations
    )

    people_params3b = PeopleParams3.new([
      {
        name: 'John',
        age: 30,
        address: john_address,
        phone_numbers: ['123-456-7890']
      },
      {
        name: 'Jane',
        age: 25,
        address: john_address,
        phone_numbers: ['123-456-7890']
      }
    ])

    assert_equal(
      {
        value: [
          {
            name: 'John',
            age: 30,
            address: john_address,
            phone_numbers: ['123-456-7890']
          },
          {
            name: 'Jane',
            age: 25,
            address: john_address,
            phone_numbers: ['123-456-7890']
          }
        ],
        violations: {}
      },
      people_params3b.to_h
    )

    assert_equal(
      {},
      people_params3b.violations
    )
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
