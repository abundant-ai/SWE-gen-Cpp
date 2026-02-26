Building the project with Xcode/Clang 14.3 (with warnings treated as errors) fails due to unused-but-set variables inside the custom GoogleTest assertion helpers used by the project’s tests. The compiler reports:

```
error: variable 'n' set but not used [-Werror,-Wunused-but-set-variable]
```

This happens in scenarios where assertion helpers compute a value (e.g., capturing a return value from a write/format operation or counting something into a local like `int n = 0;`) solely to drive an assertion, but the variable ends up not being referenced in some compilation paths or macro expansions, so Clang treats it as “set but not used” and fails the build when `-Werror` is enabled.

In addition, the library has multiple code paths for converting Unicode text (UTF-16 and UTF-32) to UTF-8, including conversions of `wchar_t` strings (for example when formatting OS error messages on Windows via `fmt::detail::unicode_to_utf8<wchar_t>` and then using `.str()`), and these conversion paths should be unified so that UTF-16/UTF-32 inputs consistently produce the same correct UTF-8 output across platforms.

Fix the build failure under Clang/Xcode by ensuring the assertion/helper code does not trigger `-Wunused-but-set-variable` (any locals that are assigned must be meaningfully used in all relevant compilation paths). Also ensure the UTF-16/UTF-32 to UTF-8 conversion logic is consistent and works for common call sites such as `fmt::detail::unicode_to_utf8<wchar_t>` constructed from a `fmt::basic_string_view<wchar_t>`, with `.str()` returning the expected UTF-8 text. After the fix, the project should compile cleanly with `-Werror` on Xcode 14.3 and Unicode conversions should behave consistently across UTF-16, UTF-32, and `wchar_t`-based inputs.