# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::RequirementsFormatTest < Minitest::Test
  UUIDFormat = contract.format!(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
  EmailFormat = contract.format!(/\A[^@\s]+@[^@\s]+\z/)

  test 'format! object' do
    assert_instance_of BCDD::Contract::Requirements::Checker, UUIDFormat
    assert_instance_of BCDD::Contract::Requirements::Checker, EmailFormat
  end

  test 'the value checking' do
    checking1 = UUIDFormat.new('e36e451d-b76a-4c4f-89e6-af256f414b5f')
    checking2 = UUIDFormat['email@example.com']

    assert_equal({ value: 'e36e451d-b76a-4c4f-89e6-af256f414b5f', violations: {} }, checking1.to_h)
    assert_equal(
      {
        value: 'email@example.com',
        violations: { format: [/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/] }
      }, checking2.to_h
    )

    checking3 = EmailFormat['email@example.com']
    checking4 = EmailFormat.new('e36e451d-b76a-4c4f-89e6-af256f414b5f')

    assert_equal({ value: 'email@example.com', violations: {} }, checking3.to_h)
    assert_equal(
      {
        value: 'e36e451d-b76a-4c4f-89e6-af256f414b5f',
        violations: { format: [/\A[^@\s]+@[^@\s]+\z/] }
      }, checking4.to_h
    )
  end
end
