# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::UnitInvariantTest < Minitest::Test
  class ShoppingCart
    module Input
      cannot_be_nan  = ->(val, err) { err << '%p cannot be nan' if val.respond_to?(:nan?) && val.nan? }
      cannot_be_inf  = ->(val, err) { err << '%p cannot be infinite' if val.respond_to?(:infinite?) && val.infinite? }
      must_be_filled = ->(val, err) { err << 'item name must be filled' if val.empty? }
      must_be_positive = ->(label) { ->(val, err) { val.positive? or err << "#{label} (%p) must be positive" } }

      ItemName    = ::BCDD::Contract[::String]  & must_be_filled
      Quantity    = ::BCDD::Contract[::Integer] & must_be_positive['quantity']
      ValidNumber = ::BCDD::Contract[::Numeric] & cannot_be_nan & cannot_be_inf

      PricePerUnit = ValidNumber & must_be_positive['price per unit']
    end

    module Items
      module Contract
        cannot_be_negative = ->(val, err) { val.negative? and err << '%p cannot be negative' }

        ItemQuantity = ::BCDD::Contract[::Integer] & cannot_be_negative

        MustBeValid = ::BCDD::Contract[->(items, err) do
          items.each do |name, data|
            quantity_errors       = ItemQuantity[data[:quantity]].errors
            item_name_errors      = Input::ItemName[name].errors
            price_per_unit_errors = Input::PricePerUnit[data[:price_per_unit]].errors

            item_errors = item_name_errors + quantity_errors + price_per_unit_errors

            err << "#{name}: #{item_errors.join(', ')}" unless item_errors.empty?
          end
        end]
      end
    end

    def initialize(items = {})
      @items = +Items::Contract::MustBeValid[items]
    end

    def add_item(item_name, quantity, price_per_unit)
      Items::Contract::MustBeValid.invariant(@items) do |items|
        item_name = +Input::ItemName[item_name]

        item = items[item_name] ||= { quantity: 0, price_per_unit: 0 }

        item[:quantity]      += +Input::Quantity[quantity]
        item[:price_per_unit] = +Input::PricePerUnit[price_per_unit]
      end
    end

    def remove_item(item_name, quantity)
      Items::Contract::MustBeValid.invariant(@items) do |items|
        item_name = +Input::ItemName[item_name]
        quantity  = +Input::Quantity[quantity]

        item = items[item_name]

        ::BCDD::Contract.assert!(item_name, 'item (%p) not found')
        ::BCDD::Contract.refute!(item_name, 'item (%p) not enough quantity to remove') { quantity > item[:quantity] }

        item[:quantity] -= quantity
      end
    end

    def total_price
      (+Items::Contract::MustBeValid[@items]).sum { |_name, idata| idata[:quantity] * idata[:price_per_unit] }
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
