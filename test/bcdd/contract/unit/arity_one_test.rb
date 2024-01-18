# frozen_string_literal: true

require 'test_helper'

module BCDD::Contract
  class UnitArityOneTest < Minitest::Test
    IsEmpty  = ::BCDD::Contract(-> { _1.empty? or '%p must be empty' })
    IsFilled = ::BCDD::Contract(->(value) { value.empty? and '%p must be filled' })

    test 'arity one' do
      assert_instance_of(Module, IsEmpty)
      assert_instance_of(Module, IsFilled)

      assert_kind_of(Unit::Checker, IsEmpty)
      assert_kind_of(Unit::Checker, IsFilled)

      assert_equal('BCDD::Contract::UnitArityOneTest::IsEmpty', IsEmpty.name)
      assert_equal('BCDD::Contract::UnitArityOneTest::IsFilled', IsFilled.name)

      assert_operator IsEmpty, :===, ''
      assert_operator IsEmpty, :===, []
      refute_operator IsEmpty, :===, '1'
      refute_operator IsEmpty, :===, [2]

      assert_operator IsFilled, :===, '3'
      assert_operator IsFilled, :===, [4]
      refute_operator IsFilled, :===, ''
      refute_operator IsFilled, :===, []

      assert_equal(['[5] must be empty'], IsEmpty[[5]].errors)
      assert_equal(['"6" must be empty'], IsEmpty['6'].errors)

      assert_equal(['"" must be filled'], IsFilled[''].errors)
      assert_equal(['[] must be filled'], IsFilled[[]].errors)
    end

    FilledHash = ::BCDD::Contract[Hash] & IsFilled

    test 'composed arity one' do
      assert_instance_of(Module, FilledHash)

      assert_kind_of(Unit::Checker, FilledHash)

      assert_equal('BCDD::Contract::UnitArityOneTest::FilledHash', FilledHash.name)

      assert_operator FilledHash, :===, { a: 1 }
      refute_operator FilledHash, :===, {}
      refute_operator FilledHash, :===, [1]

      assert_equal(['{} must be filled'], FilledHash[{}].errors)
      assert_equal(['[1] must be a Hash'], FilledHash[[1]].errors)
    end
  end
end
