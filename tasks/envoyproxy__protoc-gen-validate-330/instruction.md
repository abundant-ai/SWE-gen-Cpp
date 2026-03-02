When generating validators for proto3 messages that apply enum inclusion/exclusion rules to elements of a repeated enum field, the generated code is incomplete: it references a lookup table that is never generated.

Reproduction example:

```proto
syntax = "proto3";

import "validate/validate.proto";

enum Status {
  STATUS_INVALID = 0;
  STATUS_A = 1;
  STATUS_B = 2;
  STATUS_C = 3;
}

message Request {
  repeated Status status = 1 [(validate.rules).repeated = {
    unique: true,
    items: {enum: {defined_only: true, not_in: [0]}}
  }];
}
```

After running `protoc` with `--validate_out` (Go generation), the generated validator for `Request` tries to use a symbol like `_Request_Status_NotInLookup`, but that symbol is undefined, causing compilation to fail.

The generator should correctly emit validation code for `repeated.items.enum.in` and `repeated.items.enum.not_in` rules (including when combined with `defined_only: true`) for repeated enum fields.

Expected behavior:
- Code generation succeeds without undefined symbols.
- For a repeated enum field with `items.enum.in`, each element must be one of the allowed numeric enum values; otherwise validation fails.
- For a repeated enum field with `items.enum.not_in`, each element must not be any of the disallowed numeric enum values; otherwise validation fails.
- When `items.enum.defined_only: true` is present, each element must correspond to a defined enum value in addition to any `in`/`not_in` constraints.
- These behaviors must be implemented for both Go and C++ outputs.

Actual behavior:
- Go output fails to compile due to an undefined lookup (e.g. `_Request_Status_NotInLookup`) when `repeated.items.enum.not_in` (and similarly `in`) is used.

Implement proper generation of the required lookup structures and validation logic so repeated enum element inclusion/exclusion rules work consistently and compile cleanly in both Go and C++.