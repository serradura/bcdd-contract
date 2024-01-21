- [📜 Design by Contract Example](#-design-by-contract-example)
- [A Shopping Cart](#a-shopping-cart)
  - [The implementation](#the-implementation)
    - [What are the preconditions in this code?](#what-are-the-preconditions-in-this-code)
    - [What are the postconditions in this code?](#what-are-the-postconditions-in-this-code)
    - [What is the invariant in this code?](#what-is-the-invariant-in-this-code)
- [⚖️ What are the benefits of using this pattern?](#️-what-are-the-benefits-of-using-this-pattern)
  - [How much to do this (apply DbC)?](#how-much-to-do-this-apply-dbc)
  - [Is it worth the overhead of contract checking at runtime?](#is-it-worth-the-overhead-of-contract-checking-at-runtime)
- [🏃‍♂️ How to run the application?](#️-how-to-run-the-application)

## 📜 Design by Contract Example

The **Design by Contract**, or DbC, is an approach where components define their expected behavior with preconditions, postconditions, and invariants, enhancing reliability and code understanding.

These are the key concepts of DbC:

- **Preconditions:** Conditions that must be met before a method is executed. They specify the input requirements/expectations.

- **Postconditions:** Conditions that must hold true after the method has completed its execution. They specify the guarantees or outcomes.

- **Invariants:** Invariants are conditions that should always be true for a specific module or class throughout its execution. They represent the essential properties that should never be violated.

- **Assertions:** Are statements or checks placed within the code to validate that preconditions, postconditions, and invariants are being satisfied. If an assertion fails, it indicates a violation of the contract, highlighting a potential bug or issue.

## A Shopping Cart

What if we want to create a shopping cart that:
- Features
  - Can add items to the cart
  - Can remove items from the cart
  - Can calculate the total price of the cart
  - Has a list of items with a name, quantity, and price per unit.
- To add or remove an item
  - The name must be a non-empty string.
  - The quantity must be a positive integer.
  - The per unit must be a positive valid number (numeric, not infinite or nan).
- To remove an item
  - The item name must exist in the cart.
  - The cart must have enough quantity.
  - If the quantity is zero, the item must be removed from the cart.
- Before and after each operation, the cart must be valid:
  - The items must have a valid name (not-blank), quantity (cannot be negative), and price per unit (positive valid number).
  - This is an **invariant**. It should always be true.

### The implementation

```ruby
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
```

#### What are the preconditions in this code?

- The `add_item` method expects three arguments: `item_name`, `quantity`, and `price_per_unit`.

```ruby
def add_item(item_name, quantity, price_per_unit)
  Items::Contract.invariant(@items) do |items|
    item_name = +Item::Contract::Name[item_name]

    item = items[item_name] ||= { quantity: 0, price_per_unit: 0 }

    item[:quantity]      += +Item::Contract::Quantity[quantity]
    item[:price_per_unit] = +Item::Contract::PricePerUnit[price_per_unit]
  end
end
```

**Contract:**

- The name must be a non-empty string.
- The quantity must be a positive integer.
- The per unit must be a positive valid number (numeric, not infinite or nan).

**Note:** The `+` operator is used to perform a strict validation, raising an exception if the input does not match the expected type.

- The `remove_item` method expects two arguments: `item_name` and `quantity`.

```ruby
def remove_item(item_name, quantity)
  Items::Contract.invariant(@items) do |items|
    item_name = +Item::Contract::Name[item_name]
    quantity  = +Item::Contract::Quantity[quantity]

    item = items[item_name]

    ::BCDD::Contract.assert!(item_name, 'item (%p) not found')
    ::BCDD::Contract.refute!(item_name, 'item (%p) not enough quantity to remove') { quantity > item[:quantity] }

    item[:quantity] -= quantity

    item[:quantity].then { |number| items.delete(item_name) if number.zero? }
  end
end
```

**Contract:**

- The name must be a non-empty string.
- The quantity must be a positive integer.
- The item name must exist in the cart.
- The cart must have enough quantity.

#### What are the postconditions in this code?

Did you notice that all the methods are wrapped by the `Items::Contract.invariant` method?

In this case, the `Items::Contract` contains the postconditions and the invariant.

#### What is the invariant in this code?

The invariant is the `Items::Contract` contract, which ensures that the items are valid before and after each operation.

**Contract:**

- The items must have a valid name (not-blank), quantity (cannot be negative), and price per unit (positive valid number).

## ⚖️ What are the benefits of using this pattern?

- The code will work properly, as the preconditions and postconditions are validated by each method.
- The code is simple to understand and test, as the preconditions and postconditions are explicit.
- The object is always valid, an invariant can be defined to ensure the object state is valid before and after each operation.

### How much to do this (apply DbC)?

It depends on the context. In this example, the `ShoppingCart` is a core application component, so it is worth applying DbC. However, if it was simple, it may not be worth it.

Use some or all the DbC concepts (preconditions, postconditions, invariants, assertions) to ensure the behavior of critical components.

### Is it worth the overhead of contract checking at runtime?

Having a slow and correct code is better than a fast and incorrect code. Slow is relative as an I/O (DB query, network call, etc.) operation is much slower than a contract check.

## 🏃‍♂️ How to run the application?

In the same directory as this `README`, run:

```bash
rake

# Output sample:
#
# --  Adding items  --
#
# Total Price: $7.5
#
# --  Removing items  --
#
# Total Price: $4.5
#
# --  Invalid input  --
#
# item (Apple) not enough quantity to remove
#
# --------------------------------------------
# --  Violating the invariant deliberately  --
# --------------------------------------------
#
# rake aborted!
# BCDD::Contract::Error: (Apple: (quantity: "1" must be a Integer)) (BCDD::Contract::Error)
# /.../lib/bcdd/contract/core/checking.rb:30:in `raise_validation_errors!'
# /.../lib/bcdd/contract/core/checker.rb:18:in `invariant'
# /.../examples/design_by_contract/lib/shopping_cart.rb:44:in `remove_item'
# /.../examples/design_by_contract/Rakefile:52:in `block (2 levels) in <top (required)>'
# /.../examples/design_by_contract/Rakefile:54:in `block in <top (required)>'
# Tasks: TOP => default
# (See full trace by running task with --trace)
```
