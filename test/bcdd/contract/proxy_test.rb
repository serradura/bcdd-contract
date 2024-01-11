# frozen_string_literal: true

require 'test_helper'

module BCDD::Contract
  class ProxyTest < Minitest::Test
    test 'the Proxy ancestor' do
      assert Proxy < Core::Proxy

      refute_operator Proxy, :<, Proxy::AlwaysEnabled
    end

    test 'the Proxy::AlwaysEnabled ancestor' do
      assert Proxy::AlwaysEnabled < Core::Proxy

      refute_operator Proxy::AlwaysEnabled, :<, Proxy
    end
  end
end
