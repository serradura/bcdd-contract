# frozen_string_literal: true

require 'test_helper'

module BCDD::Contract
  class UnitCacheTest < Minitest::Test
    IsString = ::BCDD::Contract.unit(String)

    module Namespace
      IsString = ::BCDD::Contract.unit(String)
    end

    test 'the factory cache' do
      assert_instance_of(Module, IsString)
      assert_kind_of(Unit::Checker, IsString)
      assert_equal('BCDD::Contract::UnitCacheTest::IsString', IsString.name)

      assert_same(IsString, Namespace::IsString)
      assert_equal('BCDD::Contract::UnitCacheTest::IsString', Namespace::IsString.name)

      assert_same(IsString, ::BCDD::Contract.unit(String))
    end
  end
end
