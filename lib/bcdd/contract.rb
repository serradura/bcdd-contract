# frozen_string_literal: true

require_relative 'contract/version'
require_relative 'contract/type'
require_relative 'contract/proxy'

module BCDD::Contract
  class Error < StandardError; end
end
