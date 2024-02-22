# frozen_string_literal: true

require 'bundler/inline'

$LOAD_PATH.unshift(__dir__)

gemfile do
  source 'https://rubygems.org'

  gem 'bcdd-result', '>= 0.12.0'
  gem 'bcdd-contract', path: '../../../'
end

require 'lib/division'
