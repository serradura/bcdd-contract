# frozen_string_literal: true

module User::Repository
  include ::BCDD::Contract::Interface

  module Methods
    module Input
      Name  = ::BCDD::Contract.with(type: String, presence: proc(&:present?))
      Email = ::BCDD::Contract.with(type: String, format: /\A[^@\s]+@[^@\s]+\z/)
    end

    def create(name:, email:)
      output = super(name: +Input::Name[name], email: +Input::Email[email])

      output => ::User::Data[id: Integer, name: Input::Name, email: Input::Email]

      output
    end
  end
end
