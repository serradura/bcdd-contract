# frozen_string_literal: true

require 'test_helper'

module BCDD::Contract
  class UnitNamedTest < Minitest::Test
    ::BCDD::Contract.unit(
      is_set: ::Set,
      is_filled: ->(value, err) { err << '%pmust be filled' if value.empty? }
    )

    test 'a named (cached) unit checker' do
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
  end
end
