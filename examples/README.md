## `BCDD::Contact` Examples

> **Attention:** Each example has its own **README** with more details.

1. [Ports and Adapters](ports_and_adapters) - Implements the Ports and Adapters pattern. It uses **BCDD::Contract::Interface** to provide an interface from the application's core to other layers.

2. [Anti-Corruption Layer](anti_corruption_layer) - Implements the Anti-Corruption Layer pattern. It uses the **BCDD::Contract::Proxy** to define an inteface for a set of adapters, which will be used to translate an external interface (`vendors`) to the application's core interface.

3. [Business Processes](business_processes) - Implements a business process using the [`bcdd-result`](https://github.com/B-CDD/result) gem and uses the `bcdd-contract` to define its contract.

4. [Design by Contract](design_by_contract) - Shows how the `bcdd-contract` can be used to establish pre-conditions, post-conditions, and invariants in a class.
