# frozen_string_literal: true

module User::Repository
  include ::BCDD::Contract::Interface

  module Methods
    module Input
      is_string    = ::BCDD::Contract[String]
      is_filled    = ->(val) { val.present? or '%p must be filled' }
      email_format = ->(val) { val.match?(/\A[^@\s]+@[^@\s]+\z/) or '%p must be an email' }

      Name  = is_string & is_filled
      Email = is_string & is_filled & email_format
    end

    def create(name:, email:)
      output = super(name: +Input::Name[name], email: +Input::Email[email])

      output => ::User::Data[id: Integer, name: Input::Name, email: Input::Email]

      output
    end
  end
end
