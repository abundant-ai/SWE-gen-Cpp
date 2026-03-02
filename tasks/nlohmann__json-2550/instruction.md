Parsing JSON from containers holding raw bytes (especially `std::byte`) fails to compile in recent versions, even though similar code worked in older releases.

Currently, attempting to parse from `std::vector<std::byte>` triggers template/input-adapter compilation errors. For example:

```cpp
std::vector<std::byte> rg;
auto j = nlohmann::json::parse({rg.begin(), rg.end()});
```

fails with an error of the form:

```
error: no matching function for call to ‘... iterator_input_adapter<const char*>::iterator_input_adapter(...)’
```

and calling the iterator overload directly:

```cpp
std::vector<std::byte> rg;
auto j = nlohmann::json::parse(rg.begin(), rg.end());
```

can fail with errors such as:

```
error: cannot convert ‘char’ to ‘std::byte’ in initialization
```

This prevents using `json::parse(...)` with byte containers that represent UTF-8 JSON text.

The library should allow parsing from `std::byte` containers/iterators in the same way it supports parsing from `char`/`unsigned char` byte sequences. In particular:

- `nlohmann::json::parse(vec)` should compile when `vec` is a `std::vector<std::byte>` containing the bytes of a JSON document.
- `nlohmann::json::parse(first, last)` should compile and work when `first`/`last` are iterators over `std::byte`.
- `nlohmann::json::parse({first, last})` (using an iterator range) should also compile and work for `std::byte` iterators.

A minimal expected behavior example is:

```cpp
auto b = [](char c){ return static_cast<std::byte>(c); };
std::vector<std::byte> vec = { b('{'), b('}') };
auto j = nlohmann::json::parse(vec);
CHECK(j.dump() == "{}");
```

At the moment, these usages fail at compile time; they should compile cleanly and parse correctly.

Additionally, compilation under C++20 should not regress due to changes around byte-like character types. In particular, enabling C++20 (where `u8"..."` literals are `char8_t[]`) must not introduce new compilation failures in parsing/lexing code paths that consume byte buffers; the parse APIs should remain usable with byte-oriented inputs in C++20 builds.