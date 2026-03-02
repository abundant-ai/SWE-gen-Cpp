The library is missing a convenient `fmt::println` API analogous to `print` but with an automatic trailing newline, despite this being a natural and commonly requested addition (similar to the C++ iostream formatting print/println facilities). Add support for `fmt::println` so users can write formatted text followed by a newline without manually appending "\n" to the format string.

Implement `fmt::println` overloads that behave like the existing `fmt::print` family, but always append a single newline after the formatted output. The API should work with both narrow and wide character output and should integrate with existing formatting features such as compile-time format strings and runtime format strings (e.g., via `fmt::runtime`). It should also support printing to `std::ostream`/`std::wostream` in the same way the library supports `fmt::print` to streams.

Expected behavior examples:

```cpp
fmt::println("Hello");            // writes "Hello\n"
fmt::println("{} {}", 1, 2);      // writes "1 2\n"
fmt::println(fmt::runtime("{}"), 42); // writes "42\n"

std::ostringstream os;
fmt::println(os, "{}", 7);        // appends "7\n" to os

fmt::println(L"{}", 42);          // writes L"42\n" to wide output
```

The newline should be appended regardless of whether the format string already ends with a newline; `println` should not attempt to detect or avoid double-newlines—its contract is to always add exactly one newline after formatting.

The change should compile cleanly when including `fmt/format.h` and later including stream support, and it must not introduce specialization/ODR issues with existing formatters such as `ostream_formatter` and types formatted through `operator<<`.

After adding `fmt::println`, formatting to strings (`fmt::format`) must remain unchanged; only the printing APIs should gain the new `println` variants.