# frozen_string_literal: true

module BCDD::Contract
  class Error < StandardError
    def self.[](msg, arg_to_print = UNDEFINED)
      message = arg_to_print == UNDEFINED ? msg : format(msg, arg_to_print)

      raise new(message)
    end
  end
end
