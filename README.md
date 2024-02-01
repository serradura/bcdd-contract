<p align="center">
  <h1 align="center" id="-bcddcontract">🚦 BCDD::Contract</h1>
  <p align="center"><i>Reliable contract definition, data validation, and type checking for Ruby.</i></p>
  <p align="center">
    <img src="https://img.shields.io/badge/ruby->%3D%202.7.0-ruby.svg?colorA=99004d&colorB=cc0066" alt="Ruby">
    <a href="https://rubygems.org/gems/bcdd-contract"><img src="https://badge.fury.io/rb/bcdd-contract.svg" alt="bcdd-contract gem version" height="18"></a>
    <a href="https://codeclimate.com/github/B-CDD/contract/maintainability"><img src="https://api.codeclimate.com/v1/badges/14e87347cd2b660ae3cf/maintainability" /></a>
    <a href="https://codeclimate.com/github/B-CDD/contract/test_coverage"><img src="https://api.codeclimate.com/v1/badges/14e87347cd2b660ae3cf/test_coverage" /></a>
  </p>
</p>

- [Introduction](#introduction)
- [Features](#features)
- [Motivation](#motivation)
- [Examples](#examples)
- [Installation](#installation)
- [Usage](#usage)
  - [Contract Units](#contract-units)
    - [Lambda Based](#lambda-based)
    - [Type Based](#type-based)
    - [Union Based](#union-based)
      - [Using `nil` to define optional checkers](#using-nil-to-define-optional-checkers)
  - [Data Structure Checkers](#data-structure-checkers)
    - [List Schema](#list-schema)
    - [Hash Schema](#hash-schema)
    - [Hash key/value Pairs Schema](#hash-keyvalue-pairs-schema)
  - [Registered Checkers](#registered-checkers)
  - [Defining Interfaces](#defining-interfaces)
    - [`BCDD::Contract::Interface`](#bcddcontractinterface)
    - [`BCDD::Contract::Proxy`](#bcddcontractproxy)
  - [Assertions](#assertions)
- [Configuration](#configuration)
  - [Switchable features](#switchable-features)
  - [Non-switchable features](#non-switchable-features)
- [Reference](#reference)
  - [The Contract Checker API](#the-contract-checker-api)
    - [`.===`](#)
    - [`.to_proc`](#to_proc)
    - [`.invariant`](#invariant)
  - [The Contract Checking API](#the-contract-checking-api)
    - [Unary operators](#unary-operators)
  - [`BCDD::Contract` methods](#bcddcontract-methods)
  - [`BCDD::Contract::Assertions`](#bcddcontractassertions)
- [About](#about)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)
- [Code of Conduct](#code-of-conduct)

## Introduction

`bcdd-contract` is a library for implementing contracts in Ruby. It provides abstractions to validate data structures, perform type checks, and define contracts inlined or through proxies.

## Features

- Strict **type checking**.
- Value validation with **error messages**.
- **Data structure validation**: Hashes, Arrays, Sets.
- **Interface** mechanisms.
- **Configurable** features.
- **Pattern matching** integration.
- **More Ruby** and less DSL.
- **Simple** and easy **to use**.

## Motivation

Due to the addition of pattern matching, Ruby now has an excellent tool for doing type checks.

```ruby
def divide(a, b)
  a => Float | Integer
  b => Float | Integer

  outcome = a / b => Float | Integer
  outcome
end

divide('4', 2) # Integer === "4" does not return true (NoMatchingPatternError)
divide(4, '2') # Integer === "2" does not return true (NoMatchingPatternError)
divide(4, 2r)  # Integer === (2/1) does not return true (NoMatchingPatternError)

divide(4, 2.0) # 2.0
```

However, more is needed to implement contracts. Often, the object is of the expected type but does not have a valid state.

```ruby
# Examples of floats that are undesirable (invalid state)

divide(0.0, 0.0) # NaN
divide(0.0, 1.0) # Infinity

divide(Float::NAN, 2)      # NaN
divide(Float::INFINITY, 2) # Infinity
```

Let's see how we can use `bcdd-contract` can be used to implement contracts that will work with and without pattern matching.

```ruby
module FloatOrInt
  is_finite = ->(val) { val.finite? or "%p must be finite" }

  extend (BCDD::Contract[Float] & is_finite) | Integer
end

def divide(a, b)
  a => FloatOrInt
  b => FloatOrInt

  outcome = a / b => FloatOrInt
  outcome
end

divide('4', 2)             # FloatOrInt === "4" does not return true (NoMatchingPatternError)
divide(4, '2')             # FloatOrInt === "2" does not return true (NoMatchingPatternError)
divide(4, 2r)              # FloatOrInt === (2/1) does not return true (NoMatchingPatternError)
divide(0.0, 0.0)           # FloatOrInt === NaN does not return true (NoMatchingPatternError)
divide(0.0, 1.0)           # FloatOrInt === Infinity does not return true (NoMatchingPatternError)
divide(Float::NAN, 2)      # FloatOrInt === NaN does not return true (NoMatchingPatternError)
divide(Float::INFINITY, 2) # FloatOrInt === Infinity does not return true (NoMatchingPatternError)

divide(4, 2.0) # 2.0

# The contract can be used to validate values

FloatOrInt['1'].valid?   # false
FloatOrInt['2'].invalid? # true
FloatOrInt['3'].errors   # ['"3" must be a Float OR "3" must be a Integer']
FloatOrInt['4'].value    # "4"
FloatOrInt['5'].value!   # "5" must be a Float OR "4" must be a Integer (BCDD::Contract::Error)
```

Although all of this, the idea of contracts goes far beyond type checking or value validation. They are a way to define an expected behavior (method's inputs and outputs) and ensure pre-conditions, post-conditions, and invariants (Design by Contract concepts).

It looks good? So, let's see what more `bcdd-contract` can do.

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

## Examples

Check the [examples](examples) directory to see different applications of `bcdd-contract`.

> **Attention:** Each example has its own **README** with more details.

1. [Ports and Adapters](examples/ports_and_adapters) - Implements the Ports and Adapters pattern. It uses [**`BCDD::Contract::Interface`**](#bcddcontractinterface) to provide an interface from the application's core to other layers.

2. [Anti-Corruption Layer](examples/anti_corruption_layer) - Implements the Anti-Corruption Layer pattern. It uses the [**`BCDD::Contract::Proxy`**](#bcddcontractproxy) to define an inteface for a set of adapters, which will be used to translate an external interface (`vendors`) to the application's core interface.

3. [Business Processes](examples/business_processes) - Implements a business process using the [`bcdd-result`](https://github.com/B-CDD/result) gem and uses the `bcdd-contract` to define its contract.

4. [Design by Contract](examples/design_by_contract) - Shows how the `bcdd-contract` can be used to establish pre-conditions, post-conditions, and invariants in a class.

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bcdd-contract'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install bcdd-contract

And require it:

```ruby
require 'bcdd/contract' # or require 'bcdd-contract'
```

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

## Usage

### Contract Units

A unit can be used to check any object, use it when you need to check the type of an object or validate its value.

#### Lambda Based

There are two ways to create a unit checker using a Ruby lambda.

The difference between them is the number of arguments that the lambda receive.

**One argument**

When the lambda receives only one argument, it will be considered an error when it returns a string. Otherwise, it will be valid.

```ruby
# Using and, or keywords

BCDD::Contract[->(val) { val.empty? or "%p must be empty" }]
BCDD::Contract[->(val) { val.empty? and "%p must be filled" }]

# The same as above, but using if/unless + return

BCDD::Contract[->(val) { "%p must be empty" unless val.empty? }]
BCDD::Contract[->(val) { "%p must be filled" if val.empty? }]
```

You can also use numbered parameters to make the code more concise.

```ruby
BCDD::Contract[-> { _1.empty? or "%p must be empty" }]
BCDD::Contract[-> { _1.empty? and "%p must be filled" }]

BCDD::Contract[-> { "%p must be empty" unless _1.empty? }]
BCDD::Contract[-> { "%p must be filled" if _1.empty? }]
```

**Two arguments**

When the lambda receives two arguments, the first will be the value to be checked, and the second will be an array of errors. If the value is invalid, the lambda must add an error message to the array.

```ruby
MustBeFilled = BCDD::Contract[->(val, err) { err << "%p must be filled" if val.empty? }]

MustBeFilled[''].valid? # false
MustBeFilled[[]].valid? # false
MustBeFilled[{}].valid? # false

MustBeFilled['4'].valid?      # true
MustBeFilled[[5]].valid?      # true
MustBeFilled[{six: 6}].valid? # true

[] => MustBeFilled # MustBeFilled === [] does not return true (NoMatchingPatternError)
{} => MustBeFilled # MustBeFilled === {} does not return true (NoMatchingPatternError)

checking = MustBeFilled[[]]

checking.errors # ["[] must be filled"]
```

> Check out the [Registered Contract Checkers](#registered-contract-checkers) section to see how to avoid duplication of checker definitions.

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

#### Type Based

Pass a Ruby module or class to `BCDD::Contract[]` to create a type checker.

```ruby
IsEnumerable = BCDD::Contract[Enumerable]

IsEnumerable[[]].valid? # true
IsEnumerable[{}].valid? # true
IsEnumerable[1].valid?  # false

{} => IsEnumerable # nil
[] => IsEnumerable # nil
1  => IsEnumerable # IsEnumerable === 1 does not return true (NoMatchingPatternError)

checking = IsEnumerable[1]

checking.errors # ["1 must be a Enumerable"]
```

> Check out the [Registered Contract Checkers](#registered-contract-checkers) section to see how to avoid duplication of checker definitions.

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

#### Union Based

After creating a unit checker, you can use the methods `|` (OR) and `&` (AND) to create union/intersection checkers.

```ruby
is_filled = -> { _1.empty? and "%p must be filled" }

FilledArrayOrHash = (BCDD::Contract[Array] | Hash) & is_filled

FilledArrayOrHash[[]].valid? # false
FilledArrayOrHash[{}].valid? # false

FilledArrayOrHash[['1']].valid?      # true
FilledArrayOrHash[{one: '1'}].valid? # true

[] => FilledArrayOrHash # FilledArrayOrHash === [] does not return true (NoMatchingPatternError)
{} => FilledArrayOrHash # FilledArrayOrHash === {} does not return true (NoMatchingPatternError)

checking = FilledArrayOrHash[[]]

checking.errors # ["[] must be filled"]
```

> Check out the [Registered Contract Checkers](#registered-contract-checkers) section to see how to avoid duplication of checker definitions.

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

##### Using `nil` to define optional checkers

You can use `nil` to create optional contract checkers.

```ruby
IsStringOrNil = BCDD::Contract[String] | nil
```

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

### Data Structure Checkers

#### List Schema

Use an array to define a schema. Only one element is allowed. Use the union checker to allow multiple types.

If the element is not a checker, it will be transformed into one.

The checker only accept arrays and sets.

```ruby
ListOfString = ::BCDD::Contract([String])

ListOfString[[]].valid? # false
ListOfString[{}].valid? # false

ListOfString[['1', '2', '3']].valid?    # true
ListOfString[Set['1', '2', '3']].valid? # true

['1', '2', 3] => ListOfString # ListOfString === ["1", "2", 3] does not return true (NoMatchingPatternError)

Set['1', '2', 3] => ListOfString # ListOfString === #<Set: {"1", "2", 3}> does not return true (NoMatchingPatternError)

checking = ListOfString[[1, '2', 3]]

checking.errors
# [
#   "0: 1 must be a String",
#   "2: 3 must be a String"
# ]
```

> Check out the [Registered Contract Checkers](#registered-contract-checkers) section to see how to avoid duplication of checker definitions.

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

#### Hash Schema

Use a hash to define a schema. The keys will be used to match the keys, and the values will be transformed into checkers (if they are not). You can use any kind of checker, including other hash schemas.

```ruby
PersonParams = ::BCDD::Contract[{
  name: String,
  age: Integer,
  address: {
    street: String,
    number: Integer,
    city: String,
    state: String,
    country: String
  },
  phone_numbers: ::BCDD::Contract([String])
}]

PersonParams[{}].valid? # => false

PersonParams[{
  name: 'John',
  age: 30,
  address: {
    street: 'Main Street',
    number: 123,
    city: 'New York',
    state: 'NY',
    country: 'USA'
  },
  phone_numbers: ['+1 555 123 4567']
}].valid? # => true

params_checking = PersonParams[{
  name: 'John',
  age: '30',
  address: {
    street: 'Main Street',
    number: 123,
    city: nil,
    state: :NY,
    country: 'USA'
  },
  phone_numbers: ['+1 555 123 4567']
}]

params_checking.errors
#  {
#   :age => ["\"30\" must be a Integer"],
#   :address => {
#     :city => ["is missing"],
#     :state => [":NY must be a String"]
#   }
# }
```

> Check out the [Registered Contract Checkers](#registered-contract-checkers) section to see how to avoid duplication of checker definitions.

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

#### Hash key/value Pairs Schema

Use a hash to define a schema. The key and value will be transformed into checkers (if they are not).

```ruby
is_int_str = -> { _1.is_a?(String) && _1.match?(/\A\d+\z/) or "%p must be a Integer String" }

PlayerRankings = ::BCDD::Contract.pairs(is_int_str => { name: String, username: String })

PlayerRankings[{}].valid? # => false

PlayerRankings[{
  '1' => { name: 'John', username: 'john' },
  '2' => { name: 'Mary', username: 'mary' },
  '3' => { name: 'Paul', username: 'paul' }
}].valid? # => true

checking = PlayerRankings[{
  '1' => { name: :John, username: 'john' },
  'two' => { name: 'Mary', username: 'mary' },
  '3' => { name: 'Paul', username: 3 }
}]

checking.errors
# [
#   "1: (name: :John must be a String)",
#   "key: \"two\" must be a Integer String",
#   "3: (username: 3 must be a String)"
# ]
```

> Check out the [Registered Contract Checkers](#registered-contract-checkers) section to see how to avoid duplication of checker definitions.

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

### Registered Checkers

Sometimes you need to use the same checker in different places. To avoid code duplication, you can register a checker and use it later.

Use the `BCDD::Contract.register` method to give a name and register a checker.

You can register any kind of checker:
  - **Unit**
    - [Lambda based](#lambda-based)
    - [Type based](#type-based)
    - [Union based](#union-based)
  - **Data Structure**
    - [List schema](#list-schema)
    - [Hash schema](#hash-schema)
    - [Hash key/value pairs schema](#hash-keyvalue-pairs-schema)

```ruby
is_string = ::BCDD::Contract[::String]
is_filled = -> { _1.empty? and "%p must be filled" }

uuid_format = -> { _1.match?(/\A[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}\z/) or "%p must be a valid UUID" }
email_format = -> { _1.match?(/\A[^@\s]+@[^@\s]+\z/) or "%p must be a valid email" }

::BCDD::Contract.register(
  is_uuid: is_string & uuid_format,
  is_email: is_string & email_format,
  is_filled: is_filled
)
```

To use them, use a symbol with `BCDD::Contract[]` or a method that transforms a value into a checker.

```ruby
str_filled = ::BCDD::Contract[:is_str] & :is_filled

PersonParams = ::BCDD::Contract[{
  uuid: :is_uuid,
  name: str_filled,
  email: :is_email,
  tags: [str_filled]
}]
```

You can use registered checkers with unions and intersections.

```ruby
BCDD::Contract.register(
  is_hash: Hash,
  is_array: Array,
  is_filled: -> { _1.empty? and "%p must be filled" }
)

filled_array_or_hash = (BCDD::Contract[:is_array] | :is_hash) & :is_filled
```

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

### Defining Interfaces

#### `BCDD::Contract::Interface`

This feature allows the creation of a module that will be used as an interface.

It will check if the class that includes it or the object that extends it implements all the expected methods.

```ruby
module User::Repository
  include ::BCDD::Contract::Interface

  module Methods
    IsString = ::BCDD::Contract[String]

    def create(name:, email:)
      output = super(name: +IsString[name], email: +IsString[email])

      output => ::User::Data[id: Integer, name: IsString, email: IsString]

      output
    end
  end
end
```

Let's break down the example above.

1. The `User::Repository` module includes `BCDD::Contract::Interface`.
2. Defines the `Methods` module. It is mandatory, as these will be the methods to be implemented.
3. The `create` method is defined inside the `Method`s' module.
   1. This method receives two arguments: `name` and `email`.
   2. The arguments are checked using the `IsString` checker.
      * The `+` operator performs a strict check. An error will be raised if the value is invalid. Otherwise, the value will be returned.
   3. `super` is called to invoke the `create` method of the superclass. Which will be the class/object that includes/extends the `User::Repository` module.
   4. The `output` is checked using pattern matching.
      * The `=>` operator performs strict checks. If the value is invalid, a `NoMatchingPatternError` will be raised.
   5. The `output` is returned.

Now, let's see how to use it in a class.

```ruby
class User::Record::Repository
  include User::Repository

  def create(name:, email:)
    record = Record.create(name:, email:)

    ::User::Data.new(id: record.id, name: record.name, email: record.email)
  end
end
```

And how to use it in a module with singleton methods.

```ruby
module User::Record::Repository
  extend User::Repository

  def self.create(name:, email:)
    record = Record.create(name:, email:)

    ::User::Data.new(id: record.id, name: record.name, email: record.email)
  end
end
```

**What happend when an interface module is included/extended?**

1. An instance of the class will be a `User::Repository`.
2. The module, class, object, that extended the interface will be a `User::Repository`.

```ruby
class User::Record::Repository
  include User::Repository
end

module UserTest::RepositoryInMemory
  extend User::Repository
  # ...
end

User::Record::Repository.new.is_a?(User::Repository) # true

UserTest::RepositoryInMemory.is_a?(User::Repository) # true
```

**Why this is useful?**

Use `is_a?` to ensure that the class/object implements the expected methods.

```ruby
class User::Creation
  def initialize(repository)
    repository => User::Repository

    @repository = repository
  end

  # ...
end
```

> Access the [**Ports and Adapters example**](examples/ports_and_adapters) to see, test, and run something that uses the `BCDD::Contract::Interface`

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

#### `BCDD::Contract::Proxy`

This feature allows the creation of a class that will be used as a proxy for another objects.

The idea is to define an interface for the object that will be proxied.

Let's implement the example from the [previous section](#bcddcontractinterface) using a proxy.

```ruby
class User::Repository < BCDD::Contract::Proxy
  IsString = ::BCDD::Contract[String]

  def create(name:, email:)
    output = object.create(name: +IsString[name], email: +IsString[email])

    output => ::User::Data[id: Integer, name: IsString, email: IsString]

    output
  end
end
```

**How to use it?**

Inside the proxy you will use `object` to access the proxied object. This means the proxy must be initialized with an object. And the object must implement the methods defined in the proxy.

```ruby
class User::Record::Repository
  # ...
end

module UserTest::RepositoryInMemory
  extend self
  # ...
end

# The proxy must be initialized with an object that implements the expected methods

memory_repository = User::Repository.new(UserTest::RepositoryInMemory)

record_repository = User::Repository.new(User::Record::Repository.new)
```

> Access the [**Anti-Corruption Layer**](examples/anti_corruption_layer) to see, test, and run something that uses the `BCDD::Contract::Proxy`

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

### Assertions

Use the `BCDD::Contract.assert` method to check if a value is truthy or use the `BCDD::Contract.refute` method to check if a value is falsey.

Both methods always expect a value and a message. The third argument is optional and can be used to perform a more complex check.

If the value is falsey for an assertion or truthy for a refutation, an error will be raised with the message.

**Assertions withouth a block**

```ruby
item_name1 = nil
item_name2 = 'Item 2'

BCDD::Contract.assert!(item_name1, 'item (%p) not found')
# item (nil) not found (BCDD::Contract::Error)

BCDD::Contract.assert!(item_name2, 'item (%p) not found')
# "Item 2"
```

**Refutations withouth a block**

```ruby
allowed_quantity = 10

BCDD::Contract.refute!(20 > allowed_quantity, 'quantity is greater than allowed')
# quantity is greater than allowed (BCDD::Contract::Error)

BCDD::Contract.refute!(5 > allowed_quantity, 'quantity is greater than allowed')
# false
```

**Assertions/Refutations with a block**

You can use a block to perform a more complex check. The value passed to `assert`/`refute` will be yielded to the block.

```ruby
item_name = 'Item 1'
item_quantity = 10

# ---

quantity_to_remove = 11

BCDD::Contract.assert(item_name, 'item (%p) not enough quantity to remove') { quantity_to_remove <= item_quantity }
# item ("Item 1") not enough quantity to remove (BCDD::Contract::Error)

BCDD::Contract.refute(item_name, 'item (%p) not enough quantity to remove') { quantity_to_remove > item_quantity }
# item ("Item 1") not enough quantity to remove (BCDD::Contract::Error)


quantity_to_remove = 10

BCDD::Contract.assert(item_name, 'item (%p) not enough quantity to remove') { quantity_to_remove <= item_quantity }
# "Item 1"

BCDD::Contract.refute(item_name, 'item (%p) not enough quantity to remove') { quantity_to_remove > item_quantity }
# "Item 1"
```

> Access the [**Design by Contract**](examples/design_by_contract) to see, test, and run something that uses the `BCDD::Contract` assertions.

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

## Configuration

By default, the `BCDD::Contract` enables all its features. You can disable them by setting the configuration.

### Switchable features

```ruby
BCDD::Contract.configuration do |config|
  dev_or_test = ::Rails.env.local?

  config.proxy_enabled = dev_or_test
  config.interface_enabled = dev_or_test
  config.assertions_enabled = dev_or_test
end
```

In the example above, the `BCDD::Contract::Proxy`, `BCDD::Contract::Interface`, and `BCDD::Contract.assert`/`BCDD::Contract.refute` will be disabled in production.

###  Non-switchable features

The following variants are always enabled. You cannot disable them through the configuration.

- [`BCDD::Contract::Proxy::AlwaysEnabled`](#bcddcontractproxy).
- [`BCDD::Contract::Interface::AlwaysEnabled`](#bcddcontractinterface).
- [`BCDD::Contract.assert!`](#assertions).
- [`BCDD::Contract.refute!`](#assertions).

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

## Reference

### The Contract Checker API

This section describes the common API for all contract checkers:
- **Unit**
  - [Lambda based](#lambda-based)
  - [Type based](#type-based)
  - [Union based](#union-based)
- **Data Structure**
  - [List schema](#list-schema)
  - [Hash schema](#hash-schema)
  - [Hash key/value pairs schema](#hash-keyvalue-pairs-schema)

Let's the following contract checker to illustrate the API.

```ruby
IsFilled = BCDD::Contract[-> { _1.empty? and "%p must be filled" }]
```

#### `.===`

You can use the `===` operator to check if a value is valid. This operator is also used by the `case` statement and `pattern matching` operators.

```ruby
# ===

IsFilled === '' # false
IsFilled === [] # false

IsFilled === '1' # true

# case statement

case {}
when IsFilled
  # ...
end

# pattern matching

case []
in IsFilled
  # ...
end

'' in IsFilled # false

Set.new => IsFilled # is_filled === #<Set: {}> does not return true (NoMatchingPatternError)
```

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

#### `.to_proc`

You can use the `to_proc` method to transform a value into a checking object.

```ruby
[
  '',
  [],
  {}
].map(&IsFilled).all?(&:valid?) # false

[
  '1',
  '2',
  '3'
].map(&IsFilled).all?(&:valid?) # true
```

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

#### `.invariant`

Use the `invariant` to perform an strict check before and after the block execution.

```ruby
IsFilled.invariant([1]) { |numbers| numbers.pop }
# [] must be filled (BCDD::Contract::Error)
```

> Access the [**Design by Contract**](examples/design_by_contract) a better example of how to use `invariant`.

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

### The Contract Checking API

This section describes the common API for all contract checking objects. Objects that are created by a contract checker.

```ruby
IsFilled = BCDD::Contract[-> { _1.empty? and "%p must be filled" }]

checking = IsFilled['']

checking.valid?   # false
checking.invalid? # true
checking.errors?  # true
checking.errors   # ['"" must be filled']
checking.errors_message # '"" must be filled'

checking.value    # ""

+checking         # "" must be filled (BCDD::Contract::Error)
!checking         # "" must be filled (BCDD::Contract::Error)
checking.value!   # "" must be filled (BCDD::Contract::Error)
checking.assert!  # "" must be filled (BCDD::Contract::Error)

# ---

checking = IsFilled['John']

+checking         # "John"
!checking         # "John"
checking.value!   # "John"
checking.assert!  # "John"
```

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

#### Unary operators

You can use the unary operators `+` and `!` to perform a strict check. If the value is invalid, an error will be raised. Otherwise, the value will be returned.

```ruby
+IsFilled[''] # "" must be filled (BCDD::Contract::Error)
!IsFilled[''] # "" must be filled (BCDD::Contract::Error)

+IsFilled['John'] # "John"
!IsFilled['John'] # "John"
```

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

### `BCDD::Contract` methods

```ruby
BCDD::Contract[lambda]  # returns a unit checker
BCDD::Contract[module]  # returns a type checker
BCDD::Contract[<Array>] # returns a list schema checker
BCDD::Contract[<Hash>]  # returns a hash schema checker

BCDD::Contract(<Object>)     # alias for BCDD::Contract[<Object>]
BCDD::Contract.new(<Object>) # alias for BCDD::Contract[<Object>]

BCDD::Contract.to_proc # returns a proc that transforms a value into a checker

BCDD::Contract.pairs(<Hash>)  # returns a hash key/value pairs schema checker
BCDD::Contract.schema(<Hash>) # returns a hash schema checker
BCDD::Contract.list(<Object>) # returns a list schema checker
BCDD::Contract.unit(<Object>) # returns a unit checker (lambda/type based)

BCDD::Contract.error!(<String>) # raises a BCDD::Contract::Error

BCDD::Contract.assert(value, message, &block) # raises a BCDD::Contract::Error if the value/block is falsey
BCDD::Contract.refute(value, message, &block) # raises a BCDD::Contract::Error if the value/block is truthy

BCDD::Contract.assert!(value, message, &block) # same as BCDD::Contract.assert but cannot be disabled
BCDD::Contract.refute!(value, message, &block) # same as BCDD::Contract.refute but cannot be disabled

# Produces a BCDD::Contract::Proxy class
BCDD::Contract.proxy do
  # ...
end

# Produces a BCDD::Contract::Proxy::AlwaysEnabled class
BCDD::Contract.proxy(always_enabled: true) do
  # ...
end
```

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

### `BCDD::Contract::Assertions`

Use this module to include/extend the `BCDD::Contract` assertions (`#assert`/`#assert!` and `#refute`/`#refute!`).

The methods without bang (`#assert` and `#refute`) can be disabled through the assertions configuration.

```ruby
class User::Creation
  include BCDD::Contract::Assertions

  def initialize(repository)
    assert!(repository, '%p must be a User::Repository') { _1.repository.is_a?(User::Repository) }

    @repository = repository
  end

  # ...
end
```

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

## About

[Rodrigo Serradura](https://github.com/serradura) created this project. He is the B/CDD process/method creator and has already made similar gems like the [u-case](https://github.com/serradura/u-case) and [kind](https://github.com/serradura/kind/blob/main/lib/kind/result.rb). This gem can be used independently, but it also contains essential features that facilitate the adoption of B/CDD in code.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/B-CDD/contract. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/B-CDD/contract/blob/main/CODE_OF_CONDUCT.md).

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>

## Code of Conduct

Everyone interacting in the `BCDD::Contract` project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/B-CDD/contract/blob/main/CODE_OF_CONDUCT.md).

<p align="right"><a href="#-bcddcontract">⬆️ &nbsp;back to top</a></p>
