When using simdjson’s static-reflection support to serialize and deserialize user-defined structs, types that are “optional-like” are not handled consistently. In particular, reflection-based serialization should treat optional values and other nullable wrappers generically (based on an “optional concept”), so that any supported optional-like type serializes to JSON `null` when empty and serializes to the wrapped JSON value when present, and deserialization performs the inverse mapping.

Currently, calling `simdjson::builder::to_json_string(value)` on structs containing nullable fields can produce incorrect output and/or fail to compile depending on the wrapper type used, because the implementation is too narrowly tied to a specific optional type instead of a generic optional concept.

The library should support the following behaviors under `SIMDJSON_STATIC_REFLECTION`:

- Serializing a reflected struct with empty/absent values should emit `null` for those fields:
  - `std::optional<T>` with `std::nullopt` must serialize as `"field":null`.
  - `std::unique_ptr<T>` with `nullptr` must serialize as `"field":null`.
  - `std::shared_ptr<T>` with `nullptr` must serialize as `"field":null`.
  - Empty strings and empty vectors must serialize as `""` and `[]` respectively.

- Serializing present values must emit the wrapped value:
  - `std::optional<int>{42}` serializes as a JSON number.
  - `std::optional<std::string>{"text"}` serializes as a JSON string.
  - Non-null smart pointers serialize the pointed-to value as if the field were of the pointed-to type.

- Deserialization via `doc.get<T>()` must round-trip these representations:
  - If the JSON contains `null` for an optional-like field, the destination must become empty (`std::nullopt` / `nullptr`).
  - If the JSON contains a value, the destination must become present and contain the parsed value.
  - Round-tripping (deserialize then serialize then deserialize) should preserve values for structs containing primitive fields, strings, vectors, nested reflected structs, and optional-like fields.

- String escaping must remain correct when serializing reflected structs containing strings with quotes, backslashes, newlines/tabs, and non-ASCII characters. For example, a field containing `He said "Hello"` must be serialized with escaped quotes, and backslashes/newlines must be escaped.

Reproduction examples that must work with static reflection enabled:

1) Optional-like and smart pointer null handling
```cpp
struct EmptyValues {
  std::string empty_string;
  std::vector<int> empty_vector;
  std::optional<int> null_optional;
  std::unique_ptr<int> null_unique_ptr;
  std::shared_ptr<std::string> null_shared_ptr;
};

EmptyValues v;
v.empty_string = "";
v.null_optional = std::nullopt;
v.null_unique_ptr = nullptr;
v.null_shared_ptr = nullptr;

auto json_result = simdjson::builder::to_json_string(v);
// expected JSON contains:
// "empty_string":"", "empty_vector":[], "null_optional":null,
// "null_unique_ptr":null, "null_shared_ptr":null
```

2) Round-trip for a reflected struct
```cpp
struct kid {
  int age;
  std::string name;
  std::vector<std::string> toys;
};

simdjson::padded_string s = R"({"age":12,"name":"John","toys":["car","ball"]})"_padded;
simdjson::ondemand::parser p;
auto doc = p.iterate(s);

kid k;
doc.value().get<kid>().get(k); // should succeed and populate fields

std::string out;
simdjson::builder::to_json_string(k).get(out); // should succeed

// parsing out back into kid should reproduce the same values
```

Fix the static-reflection serialization/deserialization so it relies on a generic optional concept (rather than special-casing only one optional wrapper) and ensures the above behaviors compile and work correctly.