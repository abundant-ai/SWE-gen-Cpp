simdjson has (or is introducing) a compile-time JSON parsing facility under `simdjson::compile_time`, but there is currently no ergonomic way to write compile-time JSON values using a `_json` suffix on a string literal as shown below:

```cpp
auto my_thing = R"(
  {"attribute1": 1, "attribute2": 2}
)"_json;

// my_thing.attribute1 == 1
// my_thing.attribute2 == 2
```

Implement support for compile-time JSON strings via a `_json` user-defined literal (or equivalent public API) that produces a compile-time parsed object/value.

The compile-time parsing API must allow parsing JSON provided as a string literal template argument using `simdjson::compile_time::parse_json<...>()`, returning a `constexpr` result whose members are accessible as fields (via C++ reflection-based generation) when the JSON input is an object.

When calling:

```cpp
constexpr auto config = simdjson::compile_time::parse_json<R"({
  "port": 8080,
  "host": "localhost",
  "debug": true,
  "timeout": 30.5
})">();
```

the returned value must be usable in constant evaluation, and the following must hold:
- `config.port` is the integer `8080`
- `std::string_view(config.host)` equals `"localhost"`
- `config.debug` is `true`
- `config.timeout` is the floating-point value `30.5`

Nested objects must also be supported such that properties become nested fields. For example, parsing an object containing a nested `"database"` object must allow access like:
- `config.database.host` (string)
- `config.database.port` (integer)
- `config.database.timeout_sec` (floating-point)

Deeper nesting (3+ levels) must work as well, e.g. `config.server.tls.enabled` and `config.server.tls.min_version` must be valid constant-evaluable expressions.

The `_json` literal should integrate with the same compile-time parsing machinery so that raw string literals using `_json` can produce a value with the same semantics: field access for JSON objects, correct typing for numbers/booleans/strings, and compatibility with `constexpr`/`static_assert` usage. If invalid JSON is provided in a compile-time context, it should fail to compile with a clear error rather than producing a runtime failure.