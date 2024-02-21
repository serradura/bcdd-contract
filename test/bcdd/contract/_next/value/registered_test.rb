# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::ValueRegisteredTest < Minitest::Test
  BCDD::Contract.register!(:email, type: String, format: /\A[^@\s]+@[^@\s]+\z/)

  test 'the objects' do
    is_email = BCDD::Contract.with(email: true)

    assert_instance_of BCDD::Contract::Value::Checker, is_email
  end

  test 'the value checking' do
    is_email = BCDD::Contract.with(email: true)

    checking1 = is_email.new('email@example.com')
    checking2 = is_email[1]
    checking3 = is_email.new('1')

    assert_equal({ value: 'email@example.com', violations: {} }, checking1.to_h)
    assert_equal({ value: 1, violations: { type: [String] } }, checking2.to_h)
    assert_equal({ value: '1', violations: { format: [/\A[^@\s]+@[^@\s]+\z/] } }, checking3.to_h)
  end
end
