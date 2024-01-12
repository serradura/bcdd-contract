# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::UnitInvariantTest < Minitest::Test
  class ShoppingCart
    module Input
      is_positive = ->(label) { ->(val, err) { err << "#{label} (%p) must be positive" unless val.positive? } }

      IsString  = ::BCDD::Contract::Unit[String]
      IsInteger = ::BCDD::Contract::Unit[Integer]
      IsNumeric = ::BCDD::Contract::Unit[Numeric]

      ItemName    = IsString  & ::BCDD::Contract::Unit[->(val, err) { err << 'item name must be filled' if val.empty? }]
      Quantity    = IsInteger & ::BCDD::Contract::Unit[is_positive['quantity']]
      PricePerUnit = IsNumeric & ::BCDD::Contract::Unit[is_positive['price per unit']]
    end

    ItemsMustBeValid = ::BCDD::Contract.unit ->(items, err) do
      items.each do |name, data|
        name_errors           = Input::ItemName[name].errors
        quantity_errors       = Input::Quantity[data[:quantity]].errors
        price_per_unit_errors = Input::PricePerUnit[data[:price_per_unit]].errors

        item_errors = name_errors + quantity_errors + price_per_unit_errors

        err << "#{name}: #{item_errors.join(', ')}" unless item_errors.empty?
      end
    end

    def initialize(items = {})
      @items = +ItemsMustBeValid[items]
    end

    def add_item(item_name, quantity, price_per_unit)
      ItemsMustBeValid.invariant(@items) do |items|
        item_name = +Input::ItemName[item_name]

        items[item_name] ||= { quantity: 0, price_per_unit: 0 }
        items[item_name][:quantity]      += +Input::Quantity[quantity]
        items[item_name][:price_per_unit] = +Input::PricePerUnit[price_per_unit]
      end
    end

    def remove_item(item_name, quantity)
      ItemsMustBeValid.invariant(@items) do |items|
        item_name = +Input::ItemName[item_name]
        quantity  = +Input::Quantity[quantity]

        item = items[item_name]

        ::BCDD::Contract.error!("item (#{item_name}) not found")                     if item.nil?
        ::BCDD::Contract.error!("item (#{item_name}) not enough quantity to remove") if quantity > item[:quantity]

        item[:quantity] -= quantity
      end
    end

    def total_price
      (+ItemsMustBeValid[@items]).sum { |_name, idata| idata[:quantity] * idata[:price_per_unit] }
    end
  end

  test 'invariant viaolation' do
    cart = ShoppingCart.new

    cart.add_item('Apple', 5, 1.5)

    assert_in_delta(7.5, cart.total_price)

    cart.remove_item('Apple', 2)

    assert_in_delta(4.5, cart.total_price)

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
