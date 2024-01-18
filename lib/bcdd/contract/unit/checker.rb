# frozen_string_literal: true

module BCDD::Contract
  module Unit::Checker
    include Core::Checker

    SequenceMapper = ->(strategy1, strategy2) do
      ->(value, err) do
        strategy1.call(value, err)

        return unless err.empty?

        strategy2.call(value, err)
      end
    end

    def &(other)
      compose(other, SequenceMapper)
    end

    ParallelMapper = ->(strategy1, strategy2) do
      ->(value, err) do
        err1 = []
        err2 = []

        strategy1.call(value, err1)
        strategy2.call(value, err2)

        return if err1.empty? || err2.empty?

        err << err1.concat(err2).map { |msg| format(msg, value) }.join(' OR ')
      end
    end

    def |(other)
      compose(other, ParallelMapper)
    end

    private

    def compose(other, mapper)
      other = Unit::Factory.instance.build(other)

      composed_strategy = mapper.call(strategy, other.strategy)

      Unit::Factory.instance.new(composed_strategy)
    end

    private_constant :SequenceMapper, :ParallelMapper
  end
end
