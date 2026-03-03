In the ondemand API, users can call `raw_json()` on `ondemand::object` and `ondemand::array` to get a `std::string_view` of the original JSON text for that object/array. However, when working with a generic value (e.g., an `ondemand::value` obtained from a document, object field lookup, or array iteration), there is no direct way to obtain the raw JSON for that value unless the user first determines whether it is an array or object and then converts it to the appropriate type.

Add support for calling `raw_json()` directly on ondemand values so that code like the following works without having to branch on the value type:

```cpp
ondemand::parser parser;
auto json = R"({"value":123})"_padded;
ondemand::document doc = parser.iterate(json);
ondemand::object obj = doc.get_object();
std::string_view token = obj.raw_json();
// token should be {"value":123}
```

This should also work for arrays:

```cpp
ondemand::parser parser;
auto json = R"([1,2,3])"_padded;
ondemand::document doc = parser.iterate(json);
ondemand::array arr = doc.get_array();
std::string_view token = arr.raw_json();
// token should be [1,2,3]
```

After calling `raw_json()` on a value derived from an object/array, the user must still be able to continue using that object/array after a `reset()` call. For example, this sequence should succeed:

```cpp
ondemand::parser parser;
auto json = R"({"value":123})"_padded;
ondemand::document doc = parser.iterate(json);
ondemand::object obj = doc.get_object();
std::string_view token = obj.raw_json();
obj.reset();
uint64_t x = obj["value"]; // should read 123
```

Expected behavior: `raw_json()` is available on ondemand values (not only arrays/objects) as convenient syntactic sugar, returning the exact JSON substring corresponding to that value, and it does not prevent subsequent valid access patterns (including `reset()` followed by continued traversal).

Actual behavior: attempting to obtain raw JSON from a generic value requires manual type handling (array vs object), and the convenient `raw_json()` call is not available on values in a uniform way.