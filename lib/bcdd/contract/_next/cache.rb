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

    def exists?(name)
      store.key?(name)
    end

    def ensure_uniqueness(name)
      exists?(name) and Error['%p already registered', name]
    end

    def read(name)
      store[name] if exists?(name)
    end

    def read!(name)
      read(name) or raise(::ArgumentError, format('%p not registered', name))
    end

    def write(name, item, reserve:, force:)
      ReservedNames.guard(name) do |reserved_names|
        ensure_uniqueness(name: name) unless force

        reserved_names << name if reserve

        store[name] = item
      end
    end
  end
end
