# frozen_string_literal: true

module BCDD::Contract
  # A singleton class to store the configuration of the gem.
  #
  class Config
    include ::Singleton

    attr_accessor :proxy_enabled, :assertions_enabled

    def initialize
      self.proxy_enabled      = true
      self.assertions_enabled = true
    end

    def options
      { proxy_enabled: proxy_enabled, assertions_enabled: assertions_enabled }
    end
  end
end
