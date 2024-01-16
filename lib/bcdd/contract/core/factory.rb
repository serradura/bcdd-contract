# frozen_string_literal: true

module BCDD::Contract
  module Core::Factory
    module Callbacks
      def included(_base)
        raise Error, 'A contract checker cannot be included'
      end

      def extended(base)
        if !base.is_a?(::Module) || base.is_a?(::Class)
          raise Error, 'A contract checker can only be extended by a module'
        end

        mod = Module.new
        mod.send(:include, Core::Checker)

        base.const_set(:CHECKING, self::CHECKING)
        base.const_set(:STRATEGY, self::STRATEGY)
        base.extend(mod)
      end
    end

    def self.new(checker, checking, strategy)
      mod = ::Module.new
      mod.const_set(:CHECKING, checking)
      mod.const_set(:STRATEGY, strategy)
      mod.extend(Callbacks)
      mod.extend(checker)
    end
  end
end
