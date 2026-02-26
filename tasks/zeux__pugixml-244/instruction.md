Building pugixml with GCC/Clang using stricter floating-point promotion diagnostics (e.g. `-Werror=double-promotion`) fails due to implicit promotion of `float` arguments to `double` when passed through printf-style formatting helpers.

A common failure happens when serializing or converting floating-point values to text using the internal snprintf wrapper macro (e.g. `PUGI__SNPRINTF`). When a `float` value is formatted using a `%g`-family format string, the variadic call implicitly promotes the `float` to `double`, which triggers `-Wdouble-promotion` and becomes a hard error under `-Werror`.

Example build error observed:

```
error: implicit conversion from ‘float’ to ‘double’ when passing argument to function [-Werror=double-promotion]
PUGI__SNPRINTF(buf, "%.9g", value);
```

The library should compile cleanly with `-Werror=double-promotion` enabled. Any places that format `float` values via variadic functions must avoid implicit promotion warnings by making the conversion explicit at the call site (e.g. passing `double(value)` instead of `value` when using `%g`/`%f` formatting).

Additionally, the same warning must not be present in the project’s test code: any printf-style formatting or other constructs that implicitly promote `float` to `double` under `-Wdouble-promotion` should be adjusted so the test suite also builds cleanly under these flags.