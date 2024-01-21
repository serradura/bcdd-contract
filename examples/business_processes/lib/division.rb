# frozen_string_literal: true

# This class ensures the division of two valid numbers.
#
# It uses BCDD::Result to represent the operation as a process
# (a series of steps to achieve a particular result).
#
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
