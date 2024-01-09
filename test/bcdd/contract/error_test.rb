# frozen_string_literal: true

require 'test_helper'

class BCDD::Contract::ErrorTest < Minitest::Test
  test 'the Error constant' do
    assert ::BCDD::Contract::Error < ::StandardError
  end
end
