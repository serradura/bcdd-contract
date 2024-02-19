# frozen_string_literal: true

module BCDD::Contract
  require_relative 'reserved_names'

  class Cache
    attr_reader :store

    def initialize
      @store = {}
    end

    def write(name, item, reserve:, force:)
      ReservedNames.guard(name) do |reserved_names|
        !force && store.key?(name) and raise ::ArgumentError, "#{name} already registered"

        reserved_names << name if reserve

        store[name] = item
      end
    end

    def read(name)
      store.key?(name) or raise(::ArgumentError, format('%p not registered', name))

      store[name]
    end
  end
end
