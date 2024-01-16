# frozen_string_literal: true

module BCDD::Contract
  module Core
    require_relative 'core/checker'
    require_relative 'core/checking'
    require_relative 'core/proxy'
    require_relative 'core/factory'
  end

  private_constant :Core
end
