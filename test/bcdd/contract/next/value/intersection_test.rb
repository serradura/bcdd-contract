# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::ValueIntersectionTest < Minitest::Test
  IsEmail = contract.with(type: String, format: /\A[^@\s]+@[^@\s]+\z/)

  test 'the objects' do
    assert_instance_of BCDD::Contract::Value::Checker, IsEmail
  end

  test 'the value checking' do
    checking1 = IsEmail.new('email@example.com')
    checking2 = IsEmail[1]
    checking3 = IsEmail.new('1')

    assert_equal({ value: 'email@example.com', violations: {} }, checking1.to_h)
    assert_equal({ value: 1, violations: { type: [String] } }, checking2.to_h)
    assert_equal({ value: '1', violations: { format: [/\A[^@\s]+@[^@\s]+\z/] } }, checking3.to_h)
  end
end
