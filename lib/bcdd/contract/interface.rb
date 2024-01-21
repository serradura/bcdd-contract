# frozen_string_literal: true

module BCDD::Contract
  module Interface
    METHODS = <<~RUBY
      def self.extended(base)
        base.singleton_class.prepend(self::Methods)
      end

      def self.included(base)
        base.prepend(self::Methods)
      end
    RUBY

    def self.included(base)
      base.module_eval(METHODS, __FILE__, __LINE__) if Config.instance.interface_enabled
    end

    module AlwaysEnabled
      def self.included(base)
        base.module_eval(Interface::METHODS, __FILE__, __LINE__)
      end
    end
  end
end
