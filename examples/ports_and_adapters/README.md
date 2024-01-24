- [🧩 Ports and Adapters Example](#-ports-and-adapters-example)
  - [The Port](#the-port)
  - [The Adapters](#the-adapters)
- [⚖️ What is the benefit of doing this?](#️-what-is-the-benefit-of-doing-this)
  - [How much to do this (create Ports and Adapters)?](#how-much-to-do-this-create-ports-and-adapters)
  - [Is it worth the overhead of contract checking at runtime?](#is-it-worth-the-overhead-of-contract-checking-at-runtime)
- [🏃‍♂️ How to run the application?](#️-how-to-run-the-application)
- [💡 Why is `User::Creation` not validating the name and email?](#-why-is-usercreation-not-validating-the-name-and-email)

## 🧩 Ports and Adapters Example

Ports and Adapters is an architectural pattern that separates the application's core logic (Ports) from external dependencies (Adapters).

This example shows how to implement a simple application using this pattern and the gem `bcdd-contract`.

Let's start seeing the code structure:

```
├── Rakefile
├── config.rb
├── db
├── app
│  └── models
│     └── user
│        ├── record
│        │  └── repository.rb
│        └── record.rb
├── lib
│  └── user
│     ├── creation.rb
│     ├── data.rb
│     └── repository.rb
└── test
   └── user_test
      └── repository.rb
```

The files and directories are organized as follows:

- `Rakefile` runs the application.
- `config.rb` file contains the configuration of the application.
- `db` directory contains the database. It is not part of the application, but it is used by the application.
- `app` directory contains "Rails" components.
- `lib` directory contains the core business logic.
- `test` directory contains the tests.

The application is a simple "user management system". It unique core functionality is to create users.

Now we understand the code structure, let's see the how the pattern is implemented.

### The Port

In this application, there is only one business process: `User::Creation` (see `lib/user/creation.rb`), which relies on the `User::Repository` (see `lib/user/repository.rb`) to persist the user.

The `User::Repository` is an example of **port**, because it is an interface/contract that defines how the core business logic will persist user records.

```ruby
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
```

### The Adapters

The `User::Repository` is implemented by two adapters:

- `User::Record::Repository` (see `app/models/user/record/repository.rb`) is an adapter that persists user records in the database (through the `User::Record`, that is an `ActiveRecord` model).

- `UserTest::Repository` (see `test/user_test/repository.rb`) is an adapter that persists user records in memory (through the `UserTest::Data`, that is a simple in-memory data structure).

## ⚖️ What is the benefit of doing this?

The benefit of doing this is that the core business logic is decoupled from the external dependencies, which makes it easier to test and promote changes in the code.

For example, if we need to change the persistence layer (start to send the data to a REST API or a Redis DB), we just need to implement a new adapter and make the business processes (`User::Creation`) use it.

### How much to do this (create Ports and Adapters)?

Use this pattern when there is a real need to decouple the core business logic from external dependencies.

You can start with a simple implementation (without Ports and Adapters) and refactor it to use this pattern when the need arises.

### Is it worth the overhead of contract checking at runtime?

You can eliminate the overhead by disabling the `BCDD::Contract::Interface`, which is enabled by default.

When it is disabled, the `BCDD::Contract::Interface` won't prepend the interface methods module to the adapter, which means that the adapter won't be checked against the interface.

To disable it, set the configuration to false:

```ruby
BCDD::Contract.configuration do |config|
  config.interface_enabled = false
end
```

## 🏃‍♂️ How to run the application?

In the same directory as this `README`, run:

```bash
rake # or rake BCDD_CONTRACT_ENABLED=enabled

# or

rake BCDD_CONTRACT_ENABLED=false
```

**Proxy enabled**

```bash
rake # or rake BCDD_CONTRACT_ENABLED=enabled

# Output sample:
#
# --  Valid input  --
#
# Created user: #<struct User::Data id=1, name="Jane", email="jane@foo.com">
# Created user: #<struct User::Data id=1, name="John", email="john@bar.com">
#
# --  Invalid input  --
#
# rake aborted!
# BCDD::Contract::Error: "jane" must be an email (BCDD::Contract::Error)
# /.../lib/bcdd/contract/core/checking.rb:26:in `raise_validation_errors!'
# /.../lib/bcdd/contract/core/checking.rb:30:in `value_or_raise_validation_errors!'
# /.../examples/ports_and_adapters/lib/user/repository.rb:18:in `create'
# /.../examples/ports_and_adapters/lib/user/creation.rb:12:in `call'
# /.../examples/ports_and_adapters/Rakefile:33:in `block in <top (required)>'
```

**Proxy disabled**

```bash
rake BCDD_CONTRACT_ENABLED=false

# Output sample:
#
# --  Valid input  --
#
# Created user: #<struct User::Data id=1, name="Jane", email="jane@foo.com">
# Created user: #<struct User::Data id=1, name="John", email="john@bar.com">
#
# --  Invalid input  --
#
# Created user: #<struct User::Data id=2, name="Jane", email="jane">
# Created user: #<struct User::Data id=3, name="", email=nil>
```

## 💡 Why is `User::Creation` not validating the name and email?

The `User::Creation` process is not validating the name and email because if it did, it wouldn't be possible to see the error messages of the `User::Repository` contract.

But in a real-world application, the `User::Creation` process would validate the name and email, as the validation is part of its business logic. The `User::Repository` contract could do the same or simpler checkings (like if the name and email are strings).

This is an example of the `User::Creation` performing validations and the `User::Repository` checkings:

```ruby
# lib/user/name.rb
module User
  module Name
    Contract = ::BCDD::Contract[String] & -> { _1.present? or '%p must be filled' }
  end
end

# lib/user/email.rb
module User
  module Email
    Contract = ::BCDD::Contract[String] & -> { _1.match?(/\A[^@\s]+@[^@\s]+\z/) or '%p must be an email' }
  end
end

# lib/user/repository.rb
module User::Repository
  include ::BCDD::Contract::Interface

  module Methods
    def create(name:, email:)
      output = super(name: +User::Name::Contract[name], email: +User::Email::Contract[email])

      output => ::User::Data[id: Integer, name: User::Name::Contract, email: User::Email::Contract]

      output
    end
  end
end

# lib/user/creation.rb
module User
  class Creation
    def initialize(repository:)
      repository => Repository

      @repository = repository
    end

    def call(name:, email:)
      name  = Name::Contract[name]
      email = Email::Contract[email]

      return [false, name.errors] if name.invalid?
      return [false, email.errors] if email.invalid?

      user_data = @repository.create(name: name.value, email: email.value)

      puts "Created user: #{user_data.inspect}"

      [true, user_data]
    end
  end
end
```

Usage:

```ruby
memory_creation = User::Creation.new(repository: UserTest::Repository.new)

memory_creation.call(name: 'Jane', email: 'jane@email.com')
# => [true, #<struct User::Data id=1, name="Jane", email="jane@email.com">

memory_creation.call(name: '', email: 'jane')
# => [false, ["\"\" must be filled"]]

memory_creation.call(name: 'Jane', email: 'jane')
# => [false, ["\"jane\" must be an email"]]
```
