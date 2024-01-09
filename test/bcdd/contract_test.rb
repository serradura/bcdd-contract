# frozen_string_literal: true

require 'test_helper'

class BCDD::ContractTest < Minitest::Test
  test 'that it has a version number' do
    refute_nil ::BCDD::Contract::VERSION
  end
end
