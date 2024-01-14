# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::AssertionsTest < Minitest::Test
  class Foo
    include ::BCDD::Contract::Assertions
  end

  test '#assert!' do
    object = Object.new

    assert_same true, Foo.new.assert!(true, 'must be true')
    assert_same object, Foo.new.assert!(object, 'must be truthy')
    assert_same(3, Foo.new.assert!(3, 'block outcome must be true') { _1 == 3 })
    assert_same(4, Foo.new.assert!(4, 'block outcome must be truthy') { object })

    assert_raises(BCDD::Contract::Error, 'false') { Foo.new.assert!(false, '%p') }
    assert_raises(BCDD::Contract::Error, 'An awesome message') { Foo.new.assert!(false, 'An awesome message') }
    assert_raises(BCDD::Contract::Error, '(1) block returned false') do
      Foo.new.assert!(1, '(%p) block returned falsey') { |one| one == 2 }
    end
    assert_raises(BCDD::Contract::Error, '2) block returned falsey') do
      Foo.new.assert!(2, '(%p) block returned falsey') { nil }
    end
  end

  test '#assert' do
    object = Object.new

    assert_same true, Foo.new.assert(true, 'must be true')
    assert_same object, Foo.new.assert(object, 'must be truthy')
    assert_same(3, Foo.new.assert(3, 'block outcome must be true') { _1 == 3 })
    assert_same(4, Foo.new.assert(4, 'block outcome must be truthy') { object })

    assert_raises(BCDD::Contract::Error, 'false') { Foo.new.assert(false, '%p') }
    assert_raises(BCDD::Contract::Error, 'An awesome message') { Foo.new.assert(false, 'An awesome message') }
    assert_raises(BCDD::Contract::Error, '(1) block returned falsey') do
      Foo.new.assert(1, '(%p) block returned falsey') { |one| one == 2 }
    end
    assert_raises(BCDD::Contract::Error, '2) block returned falsey') do
      Foo.new.assert(2, '(%p) block returned falsey') { nil }
    end
  end

  test '#refute!' do
    assert_same false, Foo.new.refute!(false, 'must be falsey')
    assert_nil Foo.new.refute!(nil, 'must be falsey')
    assert_same(3, Foo.new.refute!(3, 'block outcome must be false') { _1 != 3 })
    assert_same(4, Foo.new.refute!(4, 'block outcome must be falsey') { nil })

    assert_raises(BCDD::Contract::Error, 'true') { Foo.new.refute!(true, '%p') }
    assert_raises(BCDD::Contract::Error, 'An awesome message') { Foo.new.refute!(true, 'An awesome message') }
    assert_raises(BCDD::Contract::Error, '(1) block returned true') do
      Foo.new.refute!(1, '(%p) block returned true') { |one| one == 1 }
    end
    assert_raises(BCDD::Contract::Error, '(2) block returned truthy') do
      Foo.new.refute!(2, '(%p) block returned truthy') { Object.new }
    end
  end

  test '#refute' do
    assert_same false, Foo.new.refute(false, 'must be falsey')
    assert_nil Foo.new.refute(nil, 'must be falsey')
    assert_same(3, Foo.new.refute(3, 'block outcome must be false') { _1 != 3 })
    assert_same(4, Foo.new.refute(4, 'block outcome must be falsey') { nil })

    assert_raises(BCDD::Contract::Error, 'true') { Foo.new.refute(true, '%p') }
    assert_raises(BCDD::Contract::Error, 'An awesome message') { Foo.new.refute(true, 'An awesome message') }
    assert_raises(BCDD::Contract::Error, '(1) block returned true') do
      Foo.new.refute(1, '(%p) block returned true') { |one| one == 1 }
    end
    assert_raises(BCDD::Contract::Error, '(2) block returned truthy') do
      Foo.new.refute(2, '(%p) block returned truthy') { Object.new }
    end
  end
end
