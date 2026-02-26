The library currently doesn’t properly support formatting built-in 128-bit integers on platforms/compilers where they exist (e.g., `__int128` / `unsigned __int128`). As a result, users cannot reliably call `fmt::format`/`fmt::print` with 128-bit integer values: compilation may fail because the type is not recognized as a supported integral type, or formatting may be routed through an unintended fallback path.

Add first-class support for built-in 128-bit integers when the compiler provides them. After the change, the following should work with the same formatting semantics as other signed/unsigned integers:

```cpp
__int128 s = /* some value */;
unsigned __int128 u = /* some value */;

auto a = fmt::format("{}", s);
auto b = fmt::format("{}", u);
auto c = fmt::format("{:x}", u);
auto d = fmt::format("{:+}", s);
```

Expected behavior:
- `fmt::formatter<__int128, char>` and `fmt::formatter<unsigned __int128, char>` (and the `wchar_t` variants) must be enabled/available when the built-in type exists.
- Decimal formatting (`"{}"`) must produce the correct base-10 string for both signed and unsigned 128-bit values, including negative numbers for the signed type.
- Non-decimal integer format specs that are supported for other integer types (at least hex via `x`/`X`, and sign handling via `+` for signed values) must behave consistently for 128-bit values.
- The support must be conditional: on platforms without a built-in 128-bit integer type, the public API should remain unchanged and the library should still compile without exposing/mentioning `__int128`.

Actual behavior to fix:
- Passing a built-in 128-bit integer into `fmt::format`/`fmt::print` fails to compile due to missing/disabled formatter support for that type (or it formats incorrectly via an unintended fallback), even though the platform provides a native 128-bit integer.