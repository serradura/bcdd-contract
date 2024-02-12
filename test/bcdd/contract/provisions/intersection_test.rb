# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::ProvisionsIntersectionTest < Minitest::Test
  IsEmail = contract.type!(String) & contract.format!(/\A[^@\s]+@[^@\s]+\z/)

  test 'intersection creates a new class' do
    assert_kind_of Class, IsEmail

    assert_operator IsEmail, :<, BCDD::Contract::Provisions::Object
  end

  test 'the value checking' do
    checking1 = IsEmail.new('email@example.com')
    checking2 = IsEmail.new(1)
    checking3 = IsEmail.new('1')

    assert_equal({ value: 'email@example.com', violations: {} }, checking1.to_h)
    assert_equal({ value: 1, violations: { type: [String] } }, checking2.to_h)
    assert_equal({ value: '1', violations: { format: [/\A[^@\s]+@[^@\s]+\z/] } }, checking3.to_h)
  end
end
