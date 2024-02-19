# frozen_string_literal: true

module BCDD::Contract
  class Cache
    class ReservedNames
      include ::Singleton

      attr_reader :list

      def initialize
        @list = ::Set[:schema]
      end

      def self.guard(name)
        names = instance.list

        !names.include?(name) or raise ::ArgumentError, "#{name} is a reserved name"

        yield(names)
      end
    end

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
