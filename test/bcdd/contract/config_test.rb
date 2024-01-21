# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::ConfigTest < Minitest::Test
  module Calc
    module Methods
      def add(a, b)
        BCDD::Contract.error!('a and b must be floats') unless a.is_a?(Float) && b.is_a?(Float)

        BCDD::Contract.assert!(super, '%p must be a finite float', &:finite?)
      end
    end
  end

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

    # disabled

    # -- interface

    BCDD::Contract.config.interface_enabled = false

    interface1 = Module.new { include(BCDD::Contract::Interface); const_set(:Methods, Calc::Methods) }
    interface2 = Module.new { include(BCDD::Contract::Interface::AlwaysEnabled); const_set(:Methods, Calc::Methods) }

    calc1 = Class.new { include(interface1); def add(a, b); a + b; end }
    calc2 = Class.new { include(interface2); def add(a, b); a + b; end }

    assert_equal(3, calc1.new.add(1, 2))

    assert_raises(BCDD::Contract::Error, 'a and b must be floats') { calc2.new.add(1, 2.0) }

    # -- proxy

    BCDD::Contract.config.proxy_enabled = false

    refute_kind_of(MyProxy1, MyProxy1.new(object))
    refute_kind_of(MyProxy2, MyProxy2.new(object))
    refute_kind_of(BCDD::Contract::Proxy, BCDD::Contract::Proxy.new(object))

    assert_same(object, MyProxy1.new(object))
    assert_same(object, MyProxy2.new(object))
    assert_same(object, BCDD::Contract::Proxy.new(object))

    assert_kind_of(MyProxyAlwaysEnabled1, MyProxyAlwaysEnabled1.new(object))
    assert_kind_of(MyProxyAlwaysEnabled2, MyProxyAlwaysEnabled2.new(object))
    assert_kind_of(BCDD::Contract::Proxy::AlwaysEnabled, BCDD::Contract::Proxy::AlwaysEnabled.new(object))

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

      config.interface_enabled = true

      config.assertions_enabled = true

      assert_same config, BCDD::Contract.config
      refute_predicate config, :frozen?
    end

    assert_predicate BCDD::Contract.config, :frozen?
  end

  test '#options' do
    assert_equal(
      {
        proxy_enabled: true,
        interface_enabled: true,
        assertions_enabled: true
      },
      BCDD::Contract.config.options
    )
  end
end
