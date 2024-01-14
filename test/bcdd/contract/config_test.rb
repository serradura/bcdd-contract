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

  class Foo
    include BCDD::Contract::Assertions
  end

  test 'the side effects' do
    object = Object.new

    assert(BCDD::Contract.config.proxy_enabled)
    assert(BCDD::Contract.config.assertions_enabled)

    # ---

    # enabled

    # -- proxy

    assert(MyProxy1.new(object).is_a?(MyProxy1))
    assert(MyProxy2.new(object).is_a?(MyProxy2))
    assert(BCDD::Contract::Proxy.new(object).is_a?(BCDD::Contract::Proxy))

    assert(MyProxyAlwaysEnabled1.new(object).is_a?(MyProxyAlwaysEnabled1))
    assert(MyProxyAlwaysEnabled2.new(object).is_a?(MyProxyAlwaysEnabled2))
    assert(BCDD::Contract::Proxy::AlwaysEnabled.new(object).is_a?(BCDD::Contract::Proxy::AlwaysEnabled))

    # -- assertions

    assert_raises(BCDD::Contract::Error, '#1') { BCDD::Contract.assert!(false, '#1') }
    assert_raises(BCDD::Contract::Error, '#2') { BCDD::Contract.assert!(nil, '#2') }
    assert_raises(BCDD::Contract::Error, '#3') { BCDD::Contract.assert!(3, '#3') { |num| num != 3 } }
    assert_raises(BCDD::Contract::Error, '#4') { BCDD::Contract.assert!(4, '#4') { nil } }

    assert_raises(BCDD::Contract::Error, '#5') { BCDD::Contract.refute!(true, '#5') }
    assert_raises(BCDD::Contract::Error, '#6') { BCDD::Contract.refute!(6, '#6') }
    assert_raises(BCDD::Contract::Error, '#7') { BCDD::Contract.refute!(7, '#7') { |num| num == 7 } }
    assert_raises(BCDD::Contract::Error, '#8') { BCDD::Contract.refute!(8, '#8') { |num| num } }

    assert_raises(BCDD::Contract::Error, '#1') { BCDD::Contract.assert(false, '#1') }
    assert_raises(BCDD::Contract::Error, '#2') { BCDD::Contract.assert(nil, '#2') }
    assert_raises(BCDD::Contract::Error, '#3') { BCDD::Contract.assert(3, '#3') { |num| num != 3 } }
    assert_raises(BCDD::Contract::Error, '#4') { BCDD::Contract.assert(4, '#4') { nil } }

    assert_raises(BCDD::Contract::Error, '#5') { BCDD::Contract.refute(true, '#5') }
    assert_raises(BCDD::Contract::Error, '#6') { BCDD::Contract.refute(6, '#6') }
    assert_raises(BCDD::Contract::Error, '#7') { BCDD::Contract.refute(7, '#7') { |num| num == 7 } }
    assert_raises(BCDD::Contract::Error, '#8') { BCDD::Contract.refute(8, '#8') { |num| num } }

    assert_raises(BCDD::Contract::Error, '#1') { Foo.new.assert!(false, '#1') }
    assert_raises(BCDD::Contract::Error, '#2') { Foo.new.assert!(nil, '#2') }
    assert_raises(BCDD::Contract::Error, '#3') { Foo.new.assert!(3, '#3') { |num| num != 3 } }
    assert_raises(BCDD::Contract::Error, '#4') { Foo.new.assert!(4, '#4') { nil } }

    assert_raises(BCDD::Contract::Error, '#5') { Foo.new.refute!(true, '#5') }
    assert_raises(BCDD::Contract::Error, '#6') { Foo.new.refute!(6, '#6') }
    assert_raises(BCDD::Contract::Error, '#7') { Foo.new.refute!(7, '#7') { |num| num == 7 } }
    assert_raises(BCDD::Contract::Error, '#8') { Foo.new.refute!(8, '#8') { |num| num } }

    assert_raises(BCDD::Contract::Error, '#1') { Foo.new.assert(false, '#1') }
    assert_raises(BCDD::Contract::Error, '#2') { Foo.new.assert(nil, '#2') }
    assert_raises(BCDD::Contract::Error, '#3') { Foo.new.assert(3, '#3') { |num| num != 3 } }
    assert_raises(BCDD::Contract::Error, '#4') { Foo.new.assert(4, '#4') { nil } }

    assert_raises(BCDD::Contract::Error, '#5') { Foo.new.refute(true, '#5') }
    assert_raises(BCDD::Contract::Error, '#6') { Foo.new.refute(6, '#6') }
    assert_raises(BCDD::Contract::Error, '#7') { Foo.new.refute(7, '#7') { |num| num == 7 } }
    assert_raises(BCDD::Contract::Error, '#8') { Foo.new.refute(8, '#8') { |num| num } }

    # disabled

    # -- proxy

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

    # -- assertions

    BCDD::Contract.config.assertions_enabled = false

    assert_raises(BCDD::Contract::Error, '#1') { BCDD::Contract.assert!(false, '#1') }
    assert_raises(BCDD::Contract::Error, '#2') { BCDD::Contract.assert!(nil, '#2') }
    assert_raises(BCDD::Contract::Error, '#3') { BCDD::Contract.assert!(3, '#3') { |num| num != 3 } }
    assert_raises(BCDD::Contract::Error, '#4') { BCDD::Contract.assert!(4, '#4') { nil } }

    assert_raises(BCDD::Contract::Error, '#5') { BCDD::Contract.refute!(true, '#5') }
    assert_raises(BCDD::Contract::Error, '#6') { BCDD::Contract.refute!(6, '#6') }
    assert_raises(BCDD::Contract::Error, '#7') { BCDD::Contract.refute!(7, '#7') { |num| num == 7 } }
    assert_raises(BCDD::Contract::Error, '#8') { BCDD::Contract.refute!(8, '#8') { |num| num } }

    refute BCDD::Contract.assert(false, '#1')
    refute BCDD::Contract.assert(nil, '#2')
    assert_equal 3, BCDD::Contract.assert(3, '#3') { |num| num != 3 }
    assert_equal 4, BCDD::Contract.assert(4, '#4') { nil }

    assert BCDD::Contract.refute(true, '#5')
    assert_equal 6, BCDD::Contract.refute(6, '#6')
    assert_equal 7, BCDD::Contract.refute(7, '#7') { |num| num == 7 }
    assert_equal 8, BCDD::Contract.refute(8, '#8') { |num| num }

    assert_raises(BCDD::Contract::Error, '#1') { Foo.new.assert!(false, '#1') }
    assert_raises(BCDD::Contract::Error, '#2') { Foo.new.assert!(nil, '#2') }
    assert_raises(BCDD::Contract::Error, '#3') { Foo.new.assert!(3, '#3') { |num| num != 3 } }
    assert_raises(BCDD::Contract::Error, '#4') { Foo.new.assert!(4, '#4') { nil } }

    assert_raises(BCDD::Contract::Error, '#5') { Foo.new.refute!(true, '#5') }
    assert_raises(BCDD::Contract::Error, '#6') { Foo.new.refute!(6, '#6') }
    assert_raises(BCDD::Contract::Error, '#7') { Foo.new.refute!(7, '#7') { |num| num == 7 } }
    assert_raises(BCDD::Contract::Error, '#8') { Foo.new.refute!(8, '#8') { |num| num } }

    refute Foo.new.assert(false, '#1')
    refute Foo.new.assert(nil, '#2')
    assert_equal 3, Foo.new.assert(3, '#3') { |num| num != 3 }
    assert_equal 4, Foo.new.assert(4, '#4') { nil }

    assert Foo.new.refute(true, '#5')
    assert_equal 6, Foo.new.refute(6, '#6')
    assert_equal 7, Foo.new.refute(7, '#7') { |num| num == 7 }
    assert_equal 8, Foo.new.refute(8, '#8') { |num| num }

    # ---

    BCDD::Contract.configuration do |config|
      config.proxy_enabled = true

      config.assertions_enabled = true

      assert_same config, BCDD::Contract.config
      refute_predicate config, :frozen?
    end

    assert_predicate BCDD::Contract.config, :frozen?
  end

  test '#options' do
    assert_equal(
      { proxy_enabled: true, assertions_enabled: true },
      BCDD::Contract.config.options
    )
  end
end
