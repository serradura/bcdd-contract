# frozen_string_literal: true

class ShoppingCart
  module Item
    module Contract
      finite = -> { !_1.respond_to?(:finite?) || _1.finite? }

      PricePerUnit = BCDD::Contract.with(type: Numeric, finite: finite, positive: proc(&:positive?))
      Quantity     = BCDD::Contract.with(type: Integer, positive: proc(&:positive?))
      Name         = BCDD::Contract.with(type: String, filled: -> { !_1.empty? })

      Data = BCDD::Contract.with(type: Hash, schema: { quantity: Quantity, price_per_unit: PricePerUnit })
    end
  end

  module Items
    Contract = BCDD::Contract.with(type: Hash, schema: { Item::Contract::Name => Item::Contract::Data })
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
