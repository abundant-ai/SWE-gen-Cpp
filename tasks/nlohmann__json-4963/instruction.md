In C++20, UTF-8 string literals of the form u8"..." have type const char8_t*. The library’s user-defined literals for JSON and JSON Pointer currently don’t accept char8_t input, so code like u8"{\"a\":1}"_json and u8"/a"_json_pointer fails to compile (no matching literal operator overload), even though the same literals work with ordinary string literals of type const char*.

Update the public user-defined literal operators so that both JSON parsing and JSON pointer construction work with u8-prefixed string literals in C++20.

The following usage should compile and behave the same as the existing const char* overloads:

```cpp
using nlohmann::json;

json j = u8"{\"foo\": [\"bar\", \"baz\"]}"_json;
auto p = u8"/foo/1"_json_pointer;

// p should point to the second element in foo
auto v = j[p];
```

Expected behavior:
- u8"..."_json parses the UTF-8 JSON text and produces the same json value as "..."_json.
- u8"..."_json_pointer constructs a json::json_pointer equivalent to json::json_pointer("...") and can be used with operator[]/contains the same way as existing pointer literals.
- Error behavior should remain consistent with existing pointer parsing: invalid pointers like "foo" (missing leading '/') should still throw json::parse_error with the existing messages when using json::json_pointer constructors; adding char8_t literal support must not change these semantics.

Actual behavior:
- With C++20, using u8"..."_json or u8"..."_json_pointer does not compile because there is no matching literal operator for const char8_t* input.