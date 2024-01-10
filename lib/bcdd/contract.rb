# frozen_string_literal: true

require_relative 'contract/version'
require_relative 'contract/config'
require_relative 'contract/unit'
require_relative 'contract/proxy'

# The main module of the gem.
# It contains the configuration methods and the error class.
#
module BCDD::Contract
  class Error < StandardError; end

  def self.config
    Config.instance
  end

  def self.configuration
    yield(config)

    config.freeze
  end
end
