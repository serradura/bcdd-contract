# frozen_string_literal: true

require 'test_helper'

module BCDD::Contract
  class RegisterTest < Minitest::Test
    is_empty = -> { _1.empty? or '%p must be empty' }
    is_filled = -> { _1.empty? and '%p must be filled' }

    str_and_int = ::BCDD::Contract.pairs(::String => ::Integer)
    numeric_list = ::BCDD::Contract([::Numeric])
    number_schema = ::BCDD::Contract[int: ::Integer, float: ::Float]

    ::BCDD::Contract.register(
      is_set: ::Set,
      is_empty: is_empty,
      is_filled: is_filled,
      filled_hash: ::BCDD::Contract[::Hash] & is_filled,
      str_and_int: str_and_int,
      numeric_list: numeric_list,
      number_schema: number_schema
    )

    test 'unit checkers' do
      is_set = ::BCDD::Contract[:is_set]
      is_filled = ::BCDD::Contract[:is_filled]
      is_a_filled_set1 = is_set & is_filled
      is_a_filled_set2 = ::BCDD::Contract[::Set] & :is_filled
      is_a_filled_set3 = ::BCDD::Contract[:is_set] & :is_filled

      assert_instance_of(Module, is_set)
      assert_kind_of(Unit::Checker, is_set)

      assert_instance_of(Module, is_filled)
      assert_kind_of(Unit::Checker, is_filled)

      assert_instance_of(Module, is_a_filled_set1)
      assert_kind_of(Unit::Checker, is_a_filled_set1)

      assert_instance_of(Module, is_a_filled_set2)
      assert_kind_of(Unit::Checker, is_a_filled_set2)

      assert_instance_of(Module, is_a_filled_set3)
      assert_kind_of(Unit::Checker, is_a_filled_set3)

      assert_same(is_set, BCDD::Contract[Set])
      assert_same(is_set, BCDD::Contract[:is_set])

      empty_set = Set.new
      filled_set = Set.new([1, 2, 3])

      assert_operator(is_set, :===, empty_set)
      assert_operator(is_set, :===, filled_set)
      refute_operator(is_set, :===, [])

      assert_operator(is_filled, :===, filled_set)
      assert_operator(is_filled, :===, [1])
      refute_operator(is_filled, :===, empty_set)
      refute_operator(is_filled, :===, [])

      assert_operator(is_a_filled_set1, :===, filled_set)
      refute_operator(is_a_filled_set1, :===, empty_set)
      refute_operator(is_a_filled_set1, :===, [1])

      assert_operator(is_a_filled_set2, :===, filled_set)
      refute_operator(is_a_filled_set2, :===, empty_set)
      refute_operator(is_a_filled_set2, :===, [1])

      assert_operator(is_a_filled_set3, :===, filled_set)
      refute_operator(is_a_filled_set3, :===, empty_set)
      refute_operator(is_a_filled_set3, :===, [1])
    end

    test 'composed unit checker' do
      filled_hash = ::BCDD::Contract[:filled_hash]

      assert_instance_of(Module, filled_hash)
      assert_kind_of(Unit::Checker, filled_hash)

      assert_same(filled_hash, BCDD::Contract[:filled_hash])

      assert_operator(filled_hash, :===, { one: 1, two: 2 })
      refute_operator(filled_hash, :===, {})
    end

    test 'pairs checkers' do
      str_and_int = ::BCDD::Contract[:str_and_int]

      assert_instance_of(Module, str_and_int)
      assert_kind_of(Map::Pairs::Checker, str_and_int)

      assert_same(str_and_int, BCDD::Contract[:str_and_int])

      assert_operator(str_and_int, :===, { 'one' => 1, 'two' => 2 })
      refute_operator(str_and_int, :===, { 'one' => 1, two: 2 })
    end

    test 'list checker' do
      numeric_list = ::BCDD::Contract[:numeric_list]

      assert_instance_of(Module, str_and_int)
      assert_kind_of(List::Checker, numeric_list)

      assert_same(numeric_list, BCDD::Contract[:numeric_list])

      assert_operator(numeric_list, :===, [1, 2.0, 3])
      refute_operator(numeric_list, :===, [1, 2.0, 3, 'four'])
    end

    test 'schema checker' do
      number_schema = ::BCDD::Contract[:number_schema]

      assert_instance_of(Module, number_schema)
      assert_kind_of(Map::Schema::Checker, number_schema)

      assert_same(number_schema, BCDD::Contract[:number_schema])

      assert_operator(number_schema, :===, { int: 1, float: 2.0 })
      refute_operator(number_schema, :===, { int: 1, float: 'two' })
    end

    test 'duplicate registration' do
      is_set = ::BCDD::Contract[:is_set]

      is_set2 = BCDD::Contract.register(is_set: ::Set).fetch(:is_set)

      assert_same(is_set, is_set2)
    end

    test 'invalid registry kind' do
      err = assert_raises(ArgumentError) do
        Registry::Kind[String]
      end

      assert_equal('Unknown checker type: String', err.message)
    end
  end
end
