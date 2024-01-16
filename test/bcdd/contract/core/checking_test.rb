# frozen_string_literal: true

require 'test_helper'

module BCDD::Contract
  class CoreCheckingTest < Minitest::Test
    class Foo
      include Core::Checking
    end

    test '#initialize' do
      assert_raises(Error, 'not implemented') { Foo.new(nil, nil) }
    end

    test '#errors_message' do
      assert_raises(Error, 'not implemented') { Foo.send(:allocate).errors_message }
    end
  end
end
