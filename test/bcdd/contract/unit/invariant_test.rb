# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::UnitInvariantTest < Minitest::Test
  class ShoppingCart
    module Item
      module Contract
        cannot_be_nan = ->(val) { val.respond_to?(:nan?) and val.nan? and '%p cannot be nan' }
        cannot_be_inf = ->(val) { val.respond_to?(:infinite?) and val.infinite? and '%p cannot be infinite' }
        must_be_positive = ->(label) { ->(val) { val.positive? or "#{label} (%p) must be positive" } }

        PricePerUnit = ::BCDD::Contract[::Numeric] & cannot_be_nan & cannot_be_inf & must_be_positive['price per unit']
        Quantity     = ::BCDD::Contract[::Integer] & must_be_positive['quantity']
        Name         = ::BCDD::Contract[::String]  & ->(val) { val.empty? and 'item name must be filled' }

        NameAndData = ::BCDD::Contract.pairs(Name => { quantity: Quantity, price_per_unit: PricePerUnit })
      end
    end

    module Items
      module Contract
        extend ::BCDD::Contract[::Hash] & ->(items, errors) do
          return if items.empty?

          Item::Contract::NameAndData[items].then { |it| it.valid? or errors.concat(it.errors) }
        end
      end
    end

    def initialize(items = {})
      @items = +Items::Contract[items]
    end

    def add_item(item_name, quantity, price_per_unit)
      Items::Contract.invariant(@items) do |items|
        item_name = +Item::Contract::Name[item_name]

        item = items[item_name] ||= { quantity: 0, price_per_unit: 0 }

        item[:price_per_unit] = +Item::Contract::PricePerUnit[price_per_unit]
        item[:quantity]      += +Item::Contract::Quantity[quantity]
      end
    end

    def remove_item(item_name, quantity)
      Items::Contract.invariant(@items) do |items|
        item_name = +Item::Contract::Name[item_name]
        quantity  = +Item::Contract::Quantity[quantity]

        item = items[item_name]

        ::BCDD::Contract.assert!(item_name, 'item (%p) not found')
        ::BCDD::Contract.refute!(item_name, 'item (%p) not enough quantity to remove') { quantity > item[:quantity] }

        item[:quantity] -= quantity

        item[:quantity].tap { |number| items.delete(item_name) if number.zero? }
      end
    end

    def total_price
      (+Items::Contract[@items]).sum { |_name, data| data[:quantity] * data[:price_per_unit] }
    end
  end

  test 'invariant viaolation' do
    cart = ShoppingCart.new

    cart.add_item('Apple', 5, 1.5)

    assert_in_delta(7.5, cart.total_price)

    cart.remove_item('Apple', 2)

    assert_in_delta(4.5, cart.total_price)

    cart.remove_item('Apple', 3)

    assert_predicate(cart.total_price, :zero?)

    [
      -> { cart.instance_variable_set(:@items, { 'Apple' => { quantity: [-1, '1'].sample, price_per_unit: 1.5 } }) },
      -> { cart.instance_variable_set(:@items, { 'Apple' => { quantity: 1, price_per_unit: [-1.5, '1.5'].sample } }) },
      -> { cart.instance_variable_set(:@items, { ['', nil].sample => { quantity: 1, price_per_unit: 1.5 } }) }
    ].sample.call

    assert_raises(BCDD::Contract::Error) { cart.add_item('Orange', 1, 1) }
    assert_raises(BCDD::Contract::Error) { cart.remove_item('Apple', 1) }
    assert_raises(BCDD::Contract::Error) { cart.total_price }
  end
end
