# frozen_string_literal: true

module BCDD::Contract
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
end
