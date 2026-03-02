When generating Go validation code for protobuf messages using `protoc-gen-validate`, repeated-field validation rules are not composed correctly when more than one repeated rule is specified on the same field. Only one of the specified rules ends up being enforced in the generated `Validate()` method, and the other rule(s) are silently ignored.

Reproduction example:

```proto
syntax = "proto3";

import "github.com/envoyproxy/protoc-gen-validate/validate/validate.proto";

package example;

message TestMessage {
  repeated string test_field = 1 [
    (validate.rules).repeated.max_items = 9,
    (validate.rules).repeated.items.string.max_len = 64
  ];
}
```

Expected behavior:
- The generated `func (m *TestMessage) Validate() error` must enforce **both**:
  1) the container rule: `len(test_field) <= 9`
  2) the per-item rule: each element’s string rune length is `<= 64`
- If the repeated field has more than 9 items, `Validate()` should return an error indicating the field violates the `max_items` constraint.
- If any item exceeds 64 runes, `Validate()` should return an error indicating that the specific indexed element (e.g., `TestField[3]`) violates the max length constraint.
- If both kinds of violations exist, returning the first encountered error is acceptable, but neither rule may be omitted from the generated code.

Actual behavior:
- When both `(validate.rules).repeated.max_items` and `(validate.rules).repeated.items.*` rules are specified, the generated `Validate()` method only emits validation logic for one of them (e.g., only the per-item check), and the other check (e.g., the overall `max_items`) is missing.
- If you remove the per-item rule and keep only `(validate.rules).repeated.max_items`, then the generator emits the max-items check correctly, which confirms the generator is dropping rules only when multiple repeated rules are present.

Fix the Go code generation so that repeated-field validations are correctly combined: container-level repeated constraints (such as `min_items`, `max_items`, `unique`, etc.) and item-level constraints (such as `repeated.items.string.pattern`, `repeated.items.string.len/max_len`, numeric comparisons, enum in/not_in, message skip, etc.) must all be generated together when specified on the same field, and none should override or erase the others.