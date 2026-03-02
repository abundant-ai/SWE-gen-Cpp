Building the project’s unit tests with clang-19 using libc++ fails during compilation because the code instantiates `std::char_traits` for an unsupported character type (notably `unsigned char`). LLVM 19 removed the base template for `std::char_traits`, and libc++ now only provides `std::char_traits` specializations for `char`, `wchar_t`, `char8_t`, `char16_t`, `char32_t`, and user-defined character types that explicitly specialize `std::char_traits`.

When compiling certain unit tests (including tests exercising BSON/CBOR/MessagePack and some regression/deserialization coverage), clang-19 + libc++ emits errors like:

```
error: implicit instantiation of undefined template 'std::char_traits<unsigned char>'
```

The build should succeed on clang-19 with libc++ without requiring users to add their own `std::char_traits<unsigned char>` specialization.

Update the library and/or test code so that no iostream/string/stream-based types are instantiated with unsupported character types. In particular, avoid using `std::basic_string<unsigned char, std::char_traits<unsigned char>, ...>` and related stream/formatter types that cause libc++ to instantiate `std::char_traits<unsigned char>`.

After the fix, the unit tests that cover binary serialization/deserialization (e.g., `json::to_bson`, CBOR, MessagePack) and regression/deserialization scenarios must compile and run successfully with clang-19 + libc++, while preserving existing behavior and exception messages such as the `json::to_bson` top-level type checks (e.g., throwing `json::type_error` with messages like `"[json.exception.type_error.317] to serialize to BSON, top-level type must be object, but is null"` for invalid inputs).