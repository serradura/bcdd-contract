# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::ConfigTest < Minitest::Test
  class MyProxy < BCDD::Contract::Proxy
  end

  test 'the side effects' do
    object = Object.new

    assert(BCDD::Contract.config.proxy_enabled)

    assert(MyProxy.new(object).is_a?(MyProxy))
    assert(BCDD::Contract::Proxy.new(object).is_a?(BCDD::Contract::Proxy))

    BCDD::Contract.config.proxy_enabled = false

    refute(MyProxy.new(object).is_a?(MyProxy))
    refute(BCDD::Contract::Proxy.new(object).is_a?(BCDD::Contract::Proxy))

    assert_same(object, MyProxy.new(object))
    assert_same(object, BCDD::Contract::Proxy.new(object))

    BCDD::Contract.configuration do |config|
      config.proxy_enabled = true

      assert_same config, BCDD::Contract.config
      refute_predicate config, :frozen?
    end

    assert_predicate BCDD::Contract.config, :frozen?
  end
end
