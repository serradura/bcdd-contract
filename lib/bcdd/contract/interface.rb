# frozen_string_literal: true

module BCDD::Contract
  module Interface
    module Callbacks
      def extended(base)
        base.singleton_class.prepend(self::Methods)
      end

      def included(base)
        base.prepend(self::Methods)
      end
    end

    def self.included(base)
      base.extend(Callbacks) if Config.instance.interface_enabled
    end

    module AlwaysEnabled
      def self.included(base)
        base.extend(Interface::Callbacks)
      end
    end
  end
end
