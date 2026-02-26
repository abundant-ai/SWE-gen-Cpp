The library is missing a convenience printing API that appends a newline, analogous to the C++ iostream.format `println` functions. Users expect to be able to call `fmt::println` to format a string with arguments, write it to the default output stream, and automatically append a line break, but the function does not exist (or is incomplete), forcing users to call `fmt::print("{}\n", ...)` manually.

Implement `fmt::println` as a public API, with behavior consistent with `fmt::print` plus an appended newline. It should support both compile-time format strings (e.g. `fmt::println("{}", 42)`) and runtime format strings via `fmt::runtime(...)`. It must also support wide-character format strings and output (e.g. `fmt::println(L"{}", 42)`), matching the existing wide-character formatting APIs.

The formatting rules should be identical to `fmt::format`/`fmt::print`:
- Correctly format arbitrary formattable arguments.
- Reject invalid format specifiers by throwing `fmt::format_error` with the same messages as existing formatting/printing APIs.

The new API should integrate cleanly with the existing ostream-related functionality so that projects including both the core formatting header and ostream support do not run into specialization/overload issues.

Example expected usage:
```cpp
fmt::println("Hello, {}!", "world"); // writes "Hello, world!\n" to standard output
fmt::println(fmt::runtime("value={}"), 10); // runtime format string support
fmt::println(L"{}", 42); // writes wide output with trailing newline
```

Currently, attempting to use `fmt::println(...)` fails because the function is not provided. After the change, these calls should compile and behave as described, including newline emission and correct error handling for invalid format strings/specifiers.