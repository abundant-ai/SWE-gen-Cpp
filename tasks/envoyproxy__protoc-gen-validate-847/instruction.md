When generating validators for protobuf `map` fields with validation rules applied to the map key type, the `in` and `not_in` rules for `map.keys.string` can produce invalid generated code.

For example, given a message like:

```proto
message TestMessage {
  map<string, string> example = 1 [(validate.rules).map.keys.string = {in: ["missing", "missing2"]}];
}
```

The Go validator generation emits code that checks membership using a lookup map, e.g.:

```go
if _, ok := _TestMessage_Example_InLookup[key]; !ok {
    // validation error
}
```

However, the lookup variable (e.g. `_TestMessage_Example_InLookup`) is not generated/initialized anywhere, so the generated code does not compile (undefined identifier) or otherwise fails to provide the expected validation behavior.

The same class of problem also affects `not_in` on `map.keys.string` (it emits a lookup reference but does not emit the lookup definition), and the issue is not limited to Go: C++ code generation should also correctly generate any required lookup/constant structures for `in`/`not_in` rules on map keys.

Implement correct code generation so that:

1. For `map< string, V >` fields with `(validate.rules).map.keys.string = {in: [...]}` the generated validators include a properly initialized lookup structure containing all configured allowed key values, and the membership check uses it.
2. For `map< string, V >` fields with `(validate.rules).map.keys.string = {not_in: [...]}` the generated validators include a properly initialized lookup structure containing all configured disallowed key values, and the membership check uses it.
3. The generated code compiles for Go and C++ targets and enforces the intended behavior at runtime.

Concrete expected runtime behavior:

- With `in: ["foo", "bar"]`, a map containing keys `"foo"` and/or `"bar"` should pass key validation, but any key not in that set (e.g. `"baz"`) should produce a validation failure.
- With `not_in: ["foo", "bar"]`, a map containing keys `"foo"` or `"bar"` should produce a validation failure, while other keys (e.g. `"baz"`) should pass.

Also ensure this works when multiple map fields or multiple messages use these rules, without naming collisions in generated lookup variables.