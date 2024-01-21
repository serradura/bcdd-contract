# frozen_string_literal: true

require 'bundler/inline'

$LOAD_PATH.unshift(__dir__)

gemfile do
  source 'https://rubygems.org'

  gem 'bcdd-result', '>= 0.12.0'
  gem 'bcdd-contract', path: '../../'
end

require 'vendor/pay_friend/client'
require 'vendor/circle_up/client'

require 'lib/payment_gateways'

require 'app/models/payment/charge_credit_card'

