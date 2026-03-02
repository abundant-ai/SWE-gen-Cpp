Building the project with Xcode/clang 14.3 (e.g., macOS SDK 13.3) fails when warnings are treated as errors. The build stops with:

```
error: variable 'n' set but not used [-Werror,-Wunused-but-set-variable]
```

This happens in code that exercises the library’s Unicode conversion behavior and related assertion helpers, and is triggered specifically by clang’s `-Wunused-but-set-variable` diagnostics under `-Werror`.

At the same time, the library has duplicated/fragmented logic for converting UTF-16 and UTF-32 inputs into UTF-8, and this PR’s goal is to unify those conversion paths so they behave consistently.

Fix the build and unify conversion so that:

1) The project compiles cleanly under clang/Xcode 14.3 with `-Werror` enabled (no unused-but-set variables).

2) UTF-16/UTF-32 to UTF-8 conversion is implemented through a single consistent mechanism, so the behavior is identical across character widths. In particular, constructing `fmt::detail::unicode_to_utf8<wchar_t>` from a `fmt::basic_string_view<wchar_t>` must reliably produce the correct UTF-8 string via `.str()`, including for Windows error message strings (wide strings) that are later formatted into an output buffer.

3) The Windows-error formatting pipeline continues to work as expected: formatting a Windows error message into a `fmt::memory_buffer` and then comparing it to a UTF-8-converted wide error message must match exactly (including correct handling of the trailing CR/LF trimming implied by Windows error message APIs).

After the fix, the existing OS/error formatting and custom assertion behavior should remain correct, and all tests should pass without needing to relax compiler warnings.