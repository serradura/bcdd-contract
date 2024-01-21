- [📈 Business Processes](#-business-processes)
- [💻 Self-Documented Code](#-self-documented-code)
  - [Why use a division as an example?](#why-use-a-division-as-an-example)
  - [What are the challenges of dividing numbers?](#what-are-the-challenges-of-dividing-numbers)
  - [What are NaN and Infinity numbers?](#what-are-nan-and-infinity-numbers)
  - [Representing a Process as Code](#representing-a-process-as-code)
- [⚖️ What are the benefits of using this pattern?](#️-what-are-the-benefits-of-using-this-pattern)
  - [Is it worth the overhead of contract checking at runtime?](#is-it-worth-the-overhead-of-contract-checking-at-runtime)
- [🏃‍♂️ How to run the application?](#️-how-to-run-the-application)

## 📈 Business Processes

**What is a Process?**

A process is a series of steps or actions performed in a specific order to achieve an outcome. These steps streamline operations, reduce errors, and enhance productivity.

Processes can be documented, analyzed, comprehended, and continuously improved to change and adapt to new circumstances/requirements.

**What is a Business Process in Software?**

In software, a business process refers to a structured sequence of tasks or activities that embody a particular function or operation within a business.

For example, if a business involves product sales, it'll have distinct processes for receiving orders, processing payments, and shipping products. These processes are and reflect the business's core operations. So, the sum of these processes is the business or the software that automates/represents it.

## 💻 Self-Documented Code

In this example, we'll use the [`BCDD::Result`](https://github.com/B-CDD/result) and `BCDD::Contract` to express a division of two numbers.

Is this a business process? If your business involves dividing numbers, yes, it is. 😛

### Why use a division as an example?

Because it's simple to understand and complex enough to show the benefits of using this pattern.

### What are the challenges of dividing numbers?

- The dividend and divisor must be valid numbers (not `NaN` or `Infinity`).
- The divisor must be different from zero.
- If the dividend is zero, the result must be zero.
- The result must be a valid number (not `NaN` or `Infinity`).

### What are NaN and Infinity numbers?

```ruby
nan = 0.0 / 0.0 # => NaN
inf = 1.0 / 0.0 # => Infinity

nan.is_a?(Numeric) # => true
inf.is_a?(Numeric) # => true

nan / 2 # => NaN
inf / 2 # => Infinity

inf / nan # => NaN
nan / inf # => NaN
```

Yes, Ruby has these "numbers". 😅

### Representing a Process as Code

```ruby
class Division
  module Contract
    not_nan = -> { _1.respond_to?(:nan?) and _1.nan? and '%p cannot be nan' }
    not_inf = -> { _1.respond_to?(:infinite?) and _1.infinite? and '%p cannot be infinite' }

    FiniteNumber = ::BCDD::Contract[Numeric] & not_nan & not_inf
    CannotBeZero = ::BCDD::Contract[-> { _1.zero? and 'cannot be zero' }]
  end

  include ::BCDD::Result::Expectations.mixin(
    config:  { addon: { continue: true } },
    success: { division_completed: Contract::FiniteNumber },
    failure: {
      invalid_arg:      ->(value) { value in [Symbol, Array] },
      division_by_zero: ->(value) { value in [:arg2, Array] }
    }
  )

  def call(arg1, arg2)
    ::BCDD::Result.transitions(name: 'Division', desc: 'divide two numbers') do
      Given([Contract::FiniteNumber[arg1], Contract::FiniteNumber[arg2]])
        .and_then(:require_numbers)
        .and_then(:check_for_zeros)
        .and_then(:divide)
    end
  end

  private

  def require_numbers((arg1, arg2))
    arg1.invalid? and return Failure(:invalid_arg, [:arg1, arg1.errors])
    arg2.invalid? and return Failure(:invalid_arg, [:arg2, arg2.errors])

    Continue([arg1.value, arg2.value])
  end

  def check_for_zeros(numbers)
    num1 = numbers[0]
    num2 = Contract::CannotBeZero[numbers[1]]

    num2.invalid? and return Failure(:division_by_zero, [:arg2, num2.errors])

    num1.zero? and return Success(:division_completed, 0)

    Continue(numbers)
  end

  def divide((num1, num2))
    Success(:division_completed, num1 / num2)
  end
end
```

Let's break it down.

```ruby
module Contract
  module Contract
    not_nan = -> { _1.respond_to?(:nan?) and _1.nan? and '%p cannot be nan' }
    not_inf = -> { _1.respond_to?(:infinite?) and _1.infinite? and '%p cannot be infinite' }

    FiniteNumber = ::BCDD::Contract[Numeric] & not_nan & not_inf
    CannotBeZero = ::BCDD::Contract[-> { _1.zero? and 'cannot be zero' }]
  end
```

The `Contract` module defines the contracts the `Division` class uses. The `FiniteNumber` ensures the value is numeric, not `NaN` or `Infinity`. The `CannotBeZero` contract ensures the value is not zero.

The lambda is the contract unit checker. It receives two arguments: the value to be validated and an array of errors. The checker will add an error to the array when the value is invalid.

**What is a contract unit?**

It's a single or as part of a contract composition. It can perform validations and type checking and be used for pattern matching.

```ruby
include ::BCDD::Result::Expectations.mixin(
  config:  { addon: { continue: true } },
  success: { division_completed: Contract::FiniteNumber },
  failure: {
    invalid_arg:      ->(value) { value in [Symbol, Array] },
    division_by_zero: ->(value) { value in [:arg2, Array] }
  }
)
```

The `BCDD::Result::Expectations.mixin` is a mixin that adds the `Given()`, `Continue()`, `Success()`, and `Failure()` methods. It also defines a contract (the expectations) for the `Success()` and `Failure()` results. If the contract is unsatisfied, the result methods will raise an exception.

**Note:** The `Contract::FiniteNumber` is being used to type-check the `:division_completed` result.

```ruby
def call(arg1, arg2)
  ::BCDD::Result.transitions(name: 'Division', desc: 'divide two numbers') do
    Given([Contract::FiniteNumber[arg1], Contract::FiniteNumber[arg2]])
      .and_then(:require_numbers)
      .and_then(:check_for_zeros)
      .and_then(:divide)
  end
end
```

The `call` method uses the `BCDD::Result.transitions` method to track the result of each step (perform `result.transitions` to see it in action) within the business process. It starts with the `Given()` and uses the `and_then()` to chain the steps. The process will stop on the first `Success()` or `Failure()`. Based on this, the previous step must return a `Continue()` to achieve the next one.

**Note:** the inputs were transformed into contract units by using the `[]` operator.

```ruby
def require_numbers((arg1, arg2))
  arg1.invalid? and return Failure(:invalid_arg, [:arg1, arg1.errors])
  arg2.invalid? and return Failure(:invalid_arg, [:arg2, arg2.errors])

  Continue([arg1.value, arg2.value])
end
```

The `require_numbers` method receives the inputs as a tuple (an array with two elements). It checks if the inputs are valid and returns `Continue()` with the contract unit values or a `Failure()` with the contract unit errors.

```ruby
def check_for_zeros(numbers)
  num1 = numbers[0]
  num2 = Contract::CannotBeZero[numbers[1]]

  num2.invalid? and return Failure(:division_by_zero, [:arg2, num2.errors])

  num1.zero? and return Success(:division_completed, 0)

  Continue(numbers)
end
```

The `check_for_zeros` method receives the inputs as an array. It uses the `Contract::CannotBeZero` to check if the second input is zero. If it is, it returns a `Failure()` with the contract errors. If the first input is zero, it returns a `Success()` with `0` to stop the process. Otherwise, it returns a `Continue()` to continue it.

```ruby
def divide((num1, num2))
  Success(:division_completed, num1 / num2)
end
```

The `divide` method is the last step. If it was reached, it means the inputs are valid and the divisor is not zero. So, it returns a `Success()` with the result of the division.

## ⚖️ What are the benefits of using this pattern?

- The process is
  - reliable. (Contracts for inputs and outputs)
  - self-documented. (Is simple to understand)
  - simple to test. (Every possible outcome is clear)
  - simple to reuse. (The contracts and processes are reusable)
  - simple to extend. (Just add a new step)
  - simple to evolve. (The contracts and behaviors can be changed to support new requirements)
  - simple to observe, monitor. (The transitions are tracked, each step is a method)

### Is it worth the overhead of contract checking at runtime?

You can eliminate the overhead by disabling the `BCDD::Result` expectations, which are the result contract checkers. Use it in dev/test environments to ensure the contracts are satisfied and disable it in production.

```ruby
BCDD::Result.configuration do |config|
  config.feature.disable!(:expectations) if ::Rails.env.production?
end
```

## 🏃‍♂️ How to run the application?

In the same directory as this `README`, run:

```bash
rake

# Output sample:
#
# --  Failures  --
#
# #<BCDD::Result::Failure type=:invalid_arg value=[:arg1, ["\"10\" must be numeric"]]>
# #<BCDD::Result::Failure type=:invalid_arg value=[:arg2, ["\"2\" must be numeric"]]>
# #<BCDD::Result::Failure type=:invalid_arg value=[:arg1, ["cannot be nan"]]>
# #<BCDD::Result::Failure type=:invalid_arg value=[:arg2, ["cannot be infinite"]]>
# #<BCDD::Result::Failure type=:division_by_zero value=[:arg2, ["cannot be zero"]]>
# #<BCDD::Result::Failure type=:division_by_zero value=[:arg2, ["cannot be zero"]]>
#
# --  Successes  --
#
# #<BCDD::Result::Success type=:division_completed value=0>
# #<BCDD::Result::Success type=:division_completed value=0>
# #<BCDD::Result::Success type=:division_completed value=5>
```
