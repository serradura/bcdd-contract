# frozen_string_literal: true

require 'test_helper'

module BCDD::Contract
  class UnitComposedTest < Minitest::Test
    module Checker
      is_filled     = ->(val, err) { err << '%p must be filled' if val.empty? }
      has_email_fmt = ->(val, err) { err << '%p must be an email' unless val.match?(/\A[^@\s]+@[^@\s]+\z/) }

      IsString = ::BCDD::Contract.unit(String)

      Name  = IsString & is_filled
      Email = IsString & is_filled & has_email_fmt
      NameOrEmail = (IsString & is_filled) | Email
    end

    test 'a composed checker (AND only)' do
      assert_instance_of(Module, Checker::Name)
      assert_instance_of(Module, Checker::Email)

      assert_kind_of(Unit::Checker, Checker::Name)
      assert_kind_of(Unit::Checker, Checker::Email)

      assert_equal('BCDD::Contract::UnitComposedTest::Checker::Name', Checker::Name.name)
      assert_equal('BCDD::Contract::UnitComposedTest::Checker::Email', Checker::Email.name)

      assert_operator Checker::Name, :===, 'John'
      refute_operator Checker::Name, :===, ''
      refute_operator Checker::Name, :===, 1

      assert_operator Checker::Email, :===, 'john@email.com'
      refute_operator Checker::Email, :===, ''
      refute_operator Checker::Email, :===, 'john'
      refute_operator Checker::Email, :===, 1

      assert_equal(['1 must be a String'], Checker::Name[1].errors)
      assert_equal(['"" must be filled'], Checker::Name[''].errors)

      assert_equal(['1 must be a String'], Checker::Email[1].errors)
      assert_equal(['"" must be filled'], Checker::Email[''].errors)
      assert_equal(['"john" must be an email'], Checker::Email['john'].errors)
    end

    SymbolOrString = BCDD::Contract[Symbol] | String

    test 'a composed checker (OR only)' do
      assert_instance_of(Module, SymbolOrString)

      assert_kind_of(Unit::Checker, SymbolOrString)

      assert_equal('BCDD::Contract::UnitComposedTest::SymbolOrString', SymbolOrString.name)

      assert_operator SymbolOrString, :===, :sym
      assert_operator SymbolOrString, :===, 'str'
      refute_operator SymbolOrString, :===, 1

      assert_equal(['1 must be a Symbol OR 1 must be a String'], SymbolOrString[1].errors)
    end

    str_int = ->(val, err) { err << '%p must be an string integer' unless val.match?(/\A\d+\z/) }

    IntOrStrInt = (BCDD::Contract[String] & str_int) | BCDD::Contract[Integer]

    test 'a composed checker (AND + OR)' do
      assert_instance_of(Module, IntOrStrInt)

      assert_kind_of(Unit::Checker, IntOrStrInt)

      assert_equal('BCDD::Contract::UnitComposedTest::IntOrStrInt', IntOrStrInt.name)

      assert_operator IntOrStrInt, :===, 1
      assert_operator IntOrStrInt, :===, '1'
      refute_operator IntOrStrInt, :===, ''

      assert_equal(['"str" must be an string integer OR "str" must be a Integer'], IntOrStrInt['str'].errors)
    end
  end
end
