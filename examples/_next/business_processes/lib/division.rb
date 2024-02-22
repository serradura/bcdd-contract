# frozen_string_literal: true

# This class ensures the division of two valid numbers.
#
# It uses BCDD::Result to represent the operation as a process
# (a series of steps to achieve a particular result).
#
class Division
  module Contract
    FiniteNumber = ::BCDD::Contract.with(type: Numeric, finite: -> { !_1.respond_to?(:finite?) || _1.finite? })
    CannotBeZero = ::BCDD::Contract.with(not_zero: -> { !_1.zero? })
  end

  include ::BCDD::Result::Expectations.mixin(
    config:  { addon: { continue: true } },
    success: { division_completed: Contract::FiniteNumber },
    failure: {
      invalid_arg:      ->(value) { value in [Symbol, ::Hash] },
      division_by_zero: ->(value) { value in [:arg2, ::Hash] }
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
    arg1.invalid? and return Failure(:invalid_arg, [:arg1, arg1.value_and_violations])
    arg2.invalid? and return Failure(:invalid_arg, [:arg2, arg2.value_and_violations])

    Continue([arg1.value, arg2.value])
  end

  def check_for_zeros(numbers)
    num1 = numbers[0]
    num2 = Contract::CannotBeZero[numbers[1]]

    num2.invalid? and return Failure(:division_by_zero, [:arg2, num2.value_and_violations])

    num1.zero? and return Success(:division_completed, 0)

    Continue(numbers)
  end

  def divide((num1, num2))
    Success(:division_completed, num1 / num2)
  end
end
