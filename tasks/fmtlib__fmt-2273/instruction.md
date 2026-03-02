The library currently exposes and uses a custom `fmt::error_code` type along with `fmt::system_error`/`fmt::windows_error`. This creates friction for users in C++11+ codebases that already use `std::error_code` and `std::system_error`, and it also prevents seamless formatting and propagation of standard error codes.

Update the error-code and system-error APIs so that the library uses `std::error_code` instead of `fmt::error_code`.

When formatting a `std::error_code` with `fmt::format`, it should produce a string in the form `<category-name>:<value>`. For example:
- `fmt::format("{}", std::error_code(42, std::generic_category()))` should produce `"generic:42"`.
- `fmt::format("{}", std::error_code(42, std::system_category()))` should produce `"system:42"`.
- Negative values must be preserved (e.g. value `-42` formats as `"system:-42"`).
The same behavior must work for wide-formatting as well (wide format string producing a `std::wstring` with the same textual content).

On Windows, when conversion helpers such as `fmt::detail::utf16_to_utf8` encounter an invalid input (e.g., a string view that is effectively invalid for conversion), they should throw `std::system_error` whose `code().value()` equals the corresponding Windows error code (e.g. `ERROR_INVALID_PARAMETER`). The thrown exception’s `what()` text should include the same message that would be produced by formatting the Windows error using `fmt::detail::format_windows_error(..., <win-error-code>, <context-message>)` (including the provided context like "cannot convert string from UTF-16 to UTF-8").

Additionally, `fmt::system_error`-style exceptions used throughout the OS helpers must remain constructible from POSIX-style error numbers (e.g. `EDOM`) and a message, and they must continue to work with existing assertion/matcher usage that expects a system-error exception to be thrown for a specific numeric error. In other words, code that throws a system error for `EDOM` should still throw a system-error exception type that carries that numeric error code in a way that can be checked.

Overall expected behavior is that users can pass, store, throw, catch, and format `std::error_code`/`std::system_error` naturally with {fmt} without needing the custom `fmt::error_code` type, while preserving existing OS error reporting behavior and message formatting.