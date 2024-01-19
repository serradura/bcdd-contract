# frozen_string_literal: true

module BCDD::Contract
  class Registry
    include ::Singleton

    OPTIONS = ::Set[
      UNIT = :unit,
      LIST = :list,
      PAIRS = :pairs,
      SCHEMA = :schema
    ].freeze

    attr_reader :store, :names

    def initialize
      @names = {}

      @store = {
        UNIT => {},
        LIST => {},
        PAIRS => {},
        SCHEMA => {}
      }
    end

    Kind = ->(checker) do
      case checker
      when Unit::Checker then UNIT
      when List::Checker then LIST
      when Map::Pairs::Checker then PAIRS
      when Map::Schema::Checker then SCHEMA
      else raise ::ArgumentError, "Unknown checker type: #{checker.inspect}"
      end
    end

    def self.write(name, checker)
      kind = Kind[checker]

      return fetch(name) if instance.names.key?(name)

      instance.names[name] = kind

      instance.store[kind][name] = checker
    end

    def self.fetch(name)
      kind = instance.names[name]

      kind or raise(::ArgumentError, format('%p not registered', name))

      read(kind, name)
    end

    def self.unit(name)
      read(UNIT, name)
    end

    def self.read(kind, name)
      instance.store[kind][name]
    end

    private_class_method :read, :instance
  end

  private_constant :Registry
end
