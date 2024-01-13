# frozen_string_literal: true

module BCDD::Contract
  # A singleton class to store the configuration of the gem.
  #
  class Config
    include ::Singleton

    attr_accessor :proxy_enabled

    def initialize
      self.proxy_enabled = true
    end
  end
end
