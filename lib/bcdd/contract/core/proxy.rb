# frozen_string_literal: true

module BCDD::Contract
  module Core
    class Proxy
      def self.[](object)
        new(object)
      end

      def self.to_proc
        ->(object) { new(object) }
      end

      attr_reader :object

      def initialize(object)
        @object = object
      end
    end
  end

  private_constant :Core
end
