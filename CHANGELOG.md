## [Unreleased]

### Added

- Add `BCDD::Contract.config` to expose the config singleton and turn on/off features.

- Add `BCDD::Contract.configuration(&block)` to receive a block to configure the gem. After the block is executed, the configuration (config singleton) will be frozen.

- Add `BCDD::Contract::Interface`, a module to be used to create interfaces.
  - Add `BCDD::Contract::Interface::AlwaysEnabled` module to be used to create interfaces that cannot be disabled by `config.interface_enabled = false`.

- Add `BCDD::Contract::Proxy`, a class to inherit to create proxy objects.
  - Use `BCDD::Contract::Proxy::AlwaysEnabled` class to inherit and create a proxy object that cannot be disabled by `config.proxy_enabled = false`.

- Add `BCDD::Contract.proxy(always_enabled: false, &block)` to create a proxy class that can be used to check the arguments and returned values of the proxy object's methods.
  - It is a syntactic sugar of `class MyContract < BCDD::Contract::Proxy`.
  - If you pass `always_enabled: true,` the proxy object will always be enabled. Otherwise, it will be enabled only when `BCDD::Contract.config.proxy_enabled` is `true`.

- Add `BCDD::Contract.error!(message)` to raise an exception with the given message.

- Add `BCDD::Contract::Assertions` to provide assertions to be used to implement inlined contracts.
  - Add `assert!(value, message, &condition)`, `refute!(value, message, &condition)` to raise an exception with the given message if the condition is not met.
  - Add `assert` and `refute`, the behavior is the same as `assert!` and `refute!` but they checkings can be disabled by `BCDD::Contract.config.assertions_enabled`.

- Add contract checkers (a module that can be used to perform validations and type checkings)
  - The supported kinds are:
    - `BCDD::Contract.unit()` - can be used to create a unit checker (can be used to check any object).
    - `BCDD::Contract.list()` - can be used to create a list checker (can be used to check arrays and sets).
    - `BCDD::Contract.pairs()` - can be used to create a checker that ensures a hash's key and value.
    - `BCDD::Contract.schema()` - can be used to create a hash checker

- Add `BCDD::Contract[]` and `BCDD::Contract()` to create a contract checker from any known input:
  - If the input is a class, it will create a unit checker.
  - If the input is a module, it will create a unit checker.
  - If the input is a hash, it will create a schema checker.
  - If the input is an array or set, it will create a list checker.

- Add `BCDD::Contract.to_proc` to expose a proc that can be used to create a contract checker from any input.

- Add `BCDD::Contract.register` to register a contract checker to be used by `BCDD::Contract[]` and `BCDD::Contract()`.
  - The registering requires a hash where the keys (symbols) are the names/alias and the values are the contract checkers.
