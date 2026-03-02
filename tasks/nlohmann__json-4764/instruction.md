When compiling nlohmann/json as part of a C++20 module interface (e.g., a module that includes `<nlohmann/json.hpp>` in the global module fragment and then `export module json;`), recent GCC trunk/GCC with modules enabled rejects the build with errors about exported declarations “expos[ing] TU-local entity”. A typical error is:

```
error: ...json_pointer<...>::split(...) exposes TU-local entity 'template<class StringType> void nlohmann::detail::unescape(StringType&)'
note: ...detail::unescape(...) declared with internal linkage
```

A similar issue occurs for other helpers, e.g.:

```
error: ...detail::binary_reader exposes TU-local entity 'bool nlohmann::detail::little_endianness(int)'
note: ...little_endianness(int) declared with internal linkage
```

On Clang (notably Clang 16 in some configurations), building the same module can also fail with a different symptom, such as:

```
error: no matching function for call to 'unescape'
    detail::unescape(reference_token);
```

The library should be usable when wrapped in a C++20 module: a minimal program that does `import json;` and then constructs `nlohmann::json j;` must compile successfully. In particular, public templates/classes that become part of the module interface (such as `nlohmann::json_pointer` and reader/parser components like `nlohmann::detail::binary_reader`) must not depend on TU-local/internal-linkage helper functions/variables in a way that causes module interface export errors. The internal helper facilities involved in these diagnostics include `nlohmann::detail::unescape(StringType&)` and `nlohmann::detail::little_endianness(int)`: they must be declared/defined so that module compilation does not treat them as internal-linkage entities being exposed through exported declarations, and calls like `detail::unescape(reference_token)` from `json_pointer::split` must resolve correctly under module compilation.

After the fix, the library should compile as a C++20 module with current GCC and Clang without these errors, while preserving existing behavior for JSON Pointer splitting/unescaping and endianness-dependent binary reading.