The project’s validation code generator does not correctly support proto3 `optional` fields. When a message field is declared with the `optional` keyword, presence semantics should be respected during validation and code generation should correctly advertise support for this protoc feature.

Currently, using `optional` can lead to incorrect validation behavior for message fields that combine `optional` with validation rules such as `(validate.rules).message.required = true`. For example, a message like:

```proto
syntax = "proto3";

import "validate/validate.proto";

message TestMsg {
  string const = 1 [(validate.rules).string.const = "foo"];
}

message MessageRequiredButOptional {
  optional TestMsg val = 1 [(validate.rules).message.required = true];
}
```

should validate as follows:

1) If `val` is not set (field absent), validation must fail because the field is explicitly marked required via `(validate.rules).message.required = true`.
2) If `val` is set to a valid `TestMsg` (e.g., `const == "foo"`), validation must succeed.
3) If `val` is set but contains invalid nested content, validation must fail with the nested violation(s).

In addition, the plugin must correctly declare to `protoc` that it supports proto3 optional (via the code generator response’s supported features field). Without this, protoc may treat optional fields in a way that prevents correct presence-aware handling.

Implement full proto3 `optional` support so that:
- Optional fields use presence-aware validation (distinguish “unset” from “set to default/empty”, consistent with proto3 optional semantics).
- Required validation rules on optional fields behave consistently: required means the field must be present.
- The plugin reports supported features for proto3 optional in the CodeGeneratorResponse.

The end result should allow proto3 schemas using `optional` to compile and validate correctly, including the required-vs-optional interaction shown above.