Building the library with strict warning flags (notably `-Wconversion` and `-Wsign-conversion`, often with `-Werror`) produces conversion-related diagnostics that can fail the build. This occurs in normal usage such as including the public headers (e.g., `fmt/core.h` / `fmt/format.h`) and compiling code that formats typical types.

The library should compile cleanly (no warnings promoted to errors) under a strict warning set such as:

`-Wall -Wextra -Werror -pedantic -Wconversion -Wsign-conversion -Wunused -Wshadow -Wdouble-promotion -Wcast-align -Wnull-dereference`

The problems are specifically about implicit narrowing and signed/unsigned conversions in the formatting core. Examples of scenarios that must compile without warnings include:

- Implementing a custom `fmt::formatter<T, Char>` and writing string literals to the output iterator (e.g., copying bytes/characters using standard algorithms such as `std::copy_n` together with lengths obtained from functions like `std::strlen`).
- Using `fmt::basic_buffer<Char>` / `fmt::basic_memory_buffer<Char>` and code paths that compute sizes/capacities and index into buffers; these should not trigger warnings about converting between `size_t`, `int`, and other integral types.
- Writing/formatting built-in integral and floating-point types via `fmt::basic_writer` and related formatting APIs without causing sign-conversion warnings in internal arithmetic (width/precision handling, count calculations, indexing, and similar size computations).

Expected behavior: when compiled with the strict flags above (and with warnings treated as errors), the project builds successfully.

Actual behavior: compilation emits conversion/sign-conversion warnings inside the library implementation and/or headers, which can become hard errors under `-Werror`.

Fix the library so these warnings are eliminated while preserving the existing formatting behavior and API. Any updated behavior should remain compatible with common formatting usage and should not break existing formatting of standard types or custom formatters.