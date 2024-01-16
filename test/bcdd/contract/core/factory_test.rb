# frozen_string_literal: true

require 'test_helper'

module BCDD::Contract
  class CoreFactoryTest < Minitest::Test
    IsString = BCDD::Contract[->(val, err) { err << '%p is not a string' unless val.is_a?(::String) }]

    test 'that cannot be included' do
      assert_raises(Error, 'A contract checker cannot be included') do
        Class.new { include IsString }
      end

      assert_raises(Error, 'A contract checker cannot be included') do
        Module.new { include IsString }
      end
    end

    test 'that cannot be extended by a class' do
      assert_raises(Error, 'A contract checker can only be extended by a module') do
        Class.new { extend IsString }
      end
    end

    test 'that cannot be extended by a non-module' do
      assert_raises(Error, 'A contract checker can only be extended by a module') do
        Object.new.extend(IsString)
      end
    end

    test 'that can be extended by a module' do
      mod = Module.new { extend IsString }

      assert_same IsString::CHECKING, mod::CHECKING
      assert_same IsString::STRATEGY, mod::STRATEGY
      assert_kind_of Core::Checker, mod
    end
  end
end
