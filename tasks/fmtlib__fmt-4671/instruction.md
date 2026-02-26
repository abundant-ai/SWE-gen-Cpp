A C11-compatible, type-safe formatting API needs to be added to {fmt} so that C projects can call formatting/printing functions without relying on printf-style format-string type encoding. The API must be usable from plain C (C11) code and support runtime format strings while remaining type-safe via `_Generic` argument mapping.

Implement a public C header that exposes a small set of functions/macros for formatting into user-provided buffers, along with printf-like convenience wrappers. The primary formatting entry point must be callable like:

```c
char buf[100];
int ret = fmt_format(buf, sizeof(buf), "Number: {}", 42);
```

`fmt_format` must write formatted output to `buf` (up to `capacity` bytes) and return the number of characters that would be produced (excluding the null terminator), matching snprintf-style semantics. Callers may choose to add a null terminator themselves based on the returned size, so the function must be consistent about the returned size even when truncation occurs.

The API must correctly format:
- Multiple arguments in one format string (e.g. "{} + {} = {}" with 3 ints)
- Signed and unsigned integers (including large `unsigned int` values like 4294967295U)
- Floating-point values (`double`, `float` with precision like `{:.3f}`, and `long double`)
- Boolean values, characters, C strings, and pointers
- Common format specifiers supported by {fmt} such as precision, width/padding, alignment, hexadecimal, and positional arguments

Type safety requirement: arguments passed from C must be mapped to internal formatting arguments via `_Generic` macros so that passing an unsupported type produces a compile-time error (or at minimum does not compile cleanly). This mapping should cover all standard C primitive scalar types and common pointer/string forms.

The API must also provide error reporting suitable for C:
- Formatting functions return a negative error code on failure (for example, invalid format string, unsupported format spec, internal error)
- A thread-local last-error string must be retrievable so C callers can understand failures after a negative return value

Concurrency requirement: formatting calls and error reporting must be safe to use from multiple threads simultaneously (no shared global mutable state without thread-local isolation).

Custom type requirement: C callers must be able to pass a custom value along with a callback-based formatter so that user-defined types can be formatted. The callback must be able to write into a resizable output buffer supplied by the library, and failures must be reflected via negative return codes and the last-error string.

Additionally provide printf-style convenience macros/wrappers that target common use cases:
- `fmt_printf` for stdout
- `fmt_fprintf` for a `FILE*`
- `fmt_snprintf` for formatting into a buffer with capacity

Platform requirement: the API must compile as C11, including on MSVC (2019+) when using a conforming preprocessor mode, and must expose appropriate DLL export/import decoration so the C API is usable from shared libraries.

If `fmt_format(buf, cap, fmt, ...)` is called with basic examples like:
- `"Number: {}"` and `42`, the buffer content should be `"Number: 42"` and the return value should equal the produced character count (10 in this example).
- `"{} + {} = {}"` and `(1,2,3)`, the content should be `"1 + 2 = 3"`.

Any deviation (wrong output, incorrect return size, lack of type coverage, non-thread-safe error reporting, or inability to format custom types through callbacks) should be considered a bug to fix.