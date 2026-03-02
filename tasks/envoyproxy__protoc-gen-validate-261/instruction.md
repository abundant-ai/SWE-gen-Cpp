Python message validation is incomplete and inconsistent with the expected PGV (protoc-gen-validate) rule behavior for several field types. The Python runtime validator should support the remaining rule categories for repeated fields, oneof groups, and bytes fields, and it should expose a single public entrypoint `validate(proto_message)` that either returns `None` on success or raises `ValidationFailed` on failure.

Currently, calling `validate(message)` does not correctly enforce a number of constraints and/or does not provide a consistent error/exception behavior for these rule types.

When validating messages with repeated fields, `validate()` must enforce:

- `min_items` / `max_items` on repeated fields (including exact size when min==max).
- `unique = true` on repeated fields: the list must not contain duplicates.
- Per-item rules via `repeated.items.*`, including:
  - numeric comparisons such as `repeated.items.float.gt = 0` (each item must satisfy the rule)
  - string rules such as `repeated.items.string.pattern = "(?i)^[a-z0-9]+$"` and membership rules `in` / `not_in`
  - message rules such as `repeated.items.message.skip = true` (items that are messages should be skipped from validation when skip is set)
  - well-known type item rules, e.g. repeated `google.protobuf.Duration`/`Timestamp` items with constraints like `gte { nanos: 1000000 }` applied to every element
- Repeated message validation must work for messages defined in the same package and for embedded messages referenced from a different package.

When validating messages with `oneof` groups, `validate()` must enforce:

- If a `oneof` has `(validate.required) = true`, exactly one field in the group must be set. If none are set, validation must fail by raising `ValidationFailed`.
- If a field in the oneof is set, its own validation rules must still be applied (e.g., if a selected oneof field has string/number constraints).

When validating bytes fields, `validate()` must enforce bytes rules such as:

- `bytes.const`: the bytes value must exactly match the declared constant.

In addition, map sparsity should not be treated as a supported/required concept in Python: Python protobuf maps cannot be sparse, so `no_sparse` should not be implemented as a meaningful check.

The `validate(proto_message)` API must:

- Accept a generated protobuf message instance.
- Return `None` if validation passes.
- Raise `ValidationFailed` if any rule is violated.
- (Where applicable) raise `UnimplementedException` only for rules that truly are not supported by the Python validator runtime.

Example expected behavior:

- Validating a message with `repeated.min_items = 2` and only 1 element must raise `ValidationFailed`.
- Validating a message with `repeated.unique = true` and duplicate elements must raise `ValidationFailed`.
- Validating a message with a required oneof group where neither field is set must raise `ValidationFailed`.
- Validating a message with `bytes.const = "\x00\x99"` must succeed only when the bytes value is exactly `b"\x00\x99"`; any other value must raise `ValidationFailed`.