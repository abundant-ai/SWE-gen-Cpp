The code generator produces incorrect (or missing) lookup logic when validating repeated fields whose item rule is `any` with an `in` or `not_in` constraint. This affects protobuf fields like:

```protobuf
message RepeatedAnyIn {
  repeated google.protobuf.Any val = 1 [(validate.rules).repeated.items.any = {in: [
    "type.googleapis.com/google.protobuf.Duration"
  ]}];
}

message RepeatedAnyNotIn {
  repeated google.protobuf.Any val = 1 [(validate.rules).repeated.items.any = {not_in: [
    "type.googleapis.com/google.protobuf.Timestamp"
  ]}];
}
```

When validating a message containing these fields, each element of the repeated `google.protobuf.Any` should be checked against the allowed/disallowed set using the Any type URL (i.e., the `type.googleapis.com/...` string). Expected behavior:

- For the `in` rule: validation succeeds only if every `Any` element has a `type_url` that is one of the configured allowed values. If an element’s `type_url` is not in the allowed list, validation must fail.
- For the `not_in` rule: validation succeeds only if every `Any` element’s `type_url` is not in the configured disallowed values. If an element’s `type_url` is in the disallowed list, validation must fail.

Actual behavior is that the generated validator does not correctly construct and/or use the lookup for these `repeated.items.any.in` and `repeated.items.any.not_in` rules, causing invalid messages to pass validation (or valid messages to fail, depending on how the broken lookup manifests).

Fix the generator so that it correctly generates the membership lookup and per-item checks for repeated `google.protobuf.Any` items with `in` and `not_in` constraints, using the type URL strings exactly as specified in the rule. After the fix:

- A message with `val` containing an `Any` packing a `google.protobuf.Duration` must validate successfully against the `in: ["type.googleapis.com/google.protobuf.Duration"]` rule, and fail if it contains an `Any` of a different type.
- A message with `val` containing an `Any` packing a `google.protobuf.Timestamp` must fail validation against the `not_in: ["type.googleapis.com/google.protobuf.Timestamp"]` rule, and validate successfully when it contains other Any types.
