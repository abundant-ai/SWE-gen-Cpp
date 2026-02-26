Compile-time format compilation via fmt::detail::compile and FMT_STRING currently does not support most standard format_specs when the argument types are bool, integers, char, or strings. As a result, formats that work at runtime with fmt::format fail to compile (or are rejected/ignored) when used with the compile-time path.

When a format string is compiled at compile time (e.g., using FMT_STRING(...) and then formatted via fmt::format/prepared format), the implementation should support the same core format specification options that are available at runtime for these types, including:

- fill and align, including non-ASCII fill characters (any character other than '{' or '}'), e.g. "{:*>4}", "{:ж^4}", "{:^4}"
- sign options "+", "-", and space, e.g. "{:+}"
- alternate form "#" for integer bases, e.g. "{:#b}"
- zero padding flag "0", e.g. "{:04}"
- width as an integer literal or dynamic width using "{}" inside the spec, e.g. "{:4}" and "{:{}}"
- integer type specifiers b, B, d, o, x, X, e.g. "{:b}", "{:x}", "{:X}"

Expected behavior: formatting a value using a compile-time compiled format should produce the same output as fmt::format with the equivalent runtime format string for the supported types (bool/integer/char/string), including correct padding, alignment, sign handling, base prefixes for "#", and correct handling of dynamic width.

Actual behavior: using these format_specs with compile-time compilation either fails to compile or does not apply the specification correctly.

Additionally, the compile-time formatting path should not require unnecessary standard library string_view usage for string-related compile-time formatting; formatting with fmt::string_view should work cleanly in the compile-time compilation flow.

Implement the missing compile-time support so that calling fmt::format with a prepared/compiled format produced from these format strings succeeds and yields correct results for the above format specifiers, for bool, integer, char, and string arguments. Floating-point formatting at compile time is explicitly out of scope.