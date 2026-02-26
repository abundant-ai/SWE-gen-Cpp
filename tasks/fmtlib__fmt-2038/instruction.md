When using compile-time checked format strings via `FMT_STRING(...)` (and especially when `FMT_ENFORCE_COMPILE_STRING` is enabled), several valid API calls either fail to compile or produce extremely unhelpful compiler errors.

One concrete case is calling formatting with a compile-time string that contains no replacement fields and passing no formatting arguments, e.g.:

```cpp
auto s = fmt::format(FMT_STRING("42"));
```

On GCC when compiling in C++11 mode, this triggers a template-instantiation failure originating from the checked-arguments machinery. The error is effectively an "index out of range"-style failure inside the format implementation, and it does not point users to the call site or clearly explain what they did wrong. The root problem is that the internal checked argument construction (via `make_args_checked`) mishandles the case where the parameter pack of arguments is empty.

The library should correctly support compile-time checked formatting for zero-argument format strings (i.e., strings without `{}`) so that `fmt::format(FMT_STRING("noop"))` compiles and returns the original string. The same expectation applies to wide strings (`FMT_STRING(L"...")`) where relevant.

In addition, enabling `FMT_ENFORCE_COMPILE_STRING` should not break expected parts of the public API that take a format string, including (but not limited to) these forms:

- `fmt::format(FMT_STRING("{}"), 42)` and `fmt::format(FMT_STRING(L"{}"), 42)`
- `fmt::format_to(out_it, FMT_STRING("{}"), 42)`
- `fmt::format_to_n(buffer, n, FMT_STRING("{}"), value)` for both `char` and `wchar_t` buffers
- `fmt::print(style, FMT_STRING("{}"), value)` and `fmt::format(style, FMT_STRING("{}"), value)` (text styling / color formatting)
- `fmt::format(FMT_STRING("{}"), range)` for supported ranges/containers when range formatting is enabled

Currently, with `FMT_ENFORCE_COMPILE_STRING` turned on, at least several of these scenarios break unexpectedly (either compile errors or incorrect constraints), indicating that compile-time string enforcement is not consistently handled across the formatting API surface.

Fix the checked-format-string path so that:

- Zero-argument compile-time format strings compile cleanly and behave as normal formatting (return the literal content).
- GCC+C++11 does not produce a misleading deep template error for the zero-argument case.
- The above API calls remain usable under `FMT_ENFORCE_COMPILE_STRING` (i.e., enforcement should not accidentally reject supported overloads or features such as styling, chrono, ranges, `format_to`, and `format_to_n`).