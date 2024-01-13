# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::UnitCacheTest < Minitest::Test
  IsString = ::BCDD::Contract::Unit[String]

  module Namespace
    IsString = ::BCDD::Contract::Unit[String]
  end

  test 'the factory cache' do
    assert_instance_of(Module, IsString)
    assert_kind_of(BCDD::Contract::Unit::Checker, IsString)
    assert_equal('BCDD::Contract::UnitCacheTest::IsString', IsString.name)

    assert_same(IsString, Namespace::IsString)
    assert_equal('BCDD::Contract::UnitCacheTest::IsString', Namespace::IsString.name)

    assert_same(IsString, ::BCDD::Contract::Unit[String])
  end
end
