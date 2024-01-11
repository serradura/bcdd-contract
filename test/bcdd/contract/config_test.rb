# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::ConfigTest < Minitest::Test
  class MyProxy1 < BCDD::Contract::Proxy
    def inspect
      object.inspect
    end
  end

  MyProxy2 = BCDD::Contract.proxy do
    def inspect
      object.inspect
    end
  end

  class MyProxyAlwaysEnabled1 < BCDD::Contract::Proxy::AlwaysEnabled
    def inspect
      object.inspect
    end
  end

  MyProxyAlwaysEnabled2 = BCDD::Contract.proxy(always_enabled: true) do
    def inspect
      object.inspect
    end
  end

  test 'the side effects' do
    object = Object.new

    assert(BCDD::Contract.config.proxy_enabled)

    assert(MyProxy1.new(object).is_a?(MyProxy1))
    assert(MyProxy2.new(object).is_a?(MyProxy2))
    assert(BCDD::Contract::Proxy.new(object).is_a?(BCDD::Contract::Proxy))

    assert(MyProxyAlwaysEnabled1.new(object).is_a?(MyProxyAlwaysEnabled1))
    assert(MyProxyAlwaysEnabled2.new(object).is_a?(MyProxyAlwaysEnabled2))
    assert(BCDD::Contract::Proxy::AlwaysEnabled.new(object).is_a?(BCDD::Contract::Proxy::AlwaysEnabled))

    BCDD::Contract.config.proxy_enabled = false

    refute(MyProxy1.new(object).is_a?(MyProxy1))
    refute(MyProxy2.new(object).is_a?(MyProxy2))
    refute(BCDD::Contract::Proxy.new(object).is_a?(BCDD::Contract::Proxy))

    assert_same(object, MyProxy1.new(object))
    assert_same(object, MyProxy2.new(object))
    assert_same(object, BCDD::Contract::Proxy.new(object))

    assert(MyProxyAlwaysEnabled1.new(object).is_a?(MyProxyAlwaysEnabled1))
    assert(MyProxyAlwaysEnabled2.new(object).is_a?(MyProxyAlwaysEnabled2))
    assert(BCDD::Contract::Proxy::AlwaysEnabled.new(object).is_a?(BCDD::Contract::Proxy::AlwaysEnabled))

    BCDD::Contract.configuration do |config|
      config.proxy_enabled = true

      assert_same config, BCDD::Contract.config
      refute_predicate config, :frozen?
    end

    assert_predicate BCDD::Contract.config, :frozen?
  end
end
