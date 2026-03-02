The formatting library currently supports escaping strings when formatting ranges (so strings inside a formatted range appear escaped), but there is no way to request this escaped-string behavior directly when formatting a standalone string. Add support for the '?' presentation type for string-like arguments so users can explicitly request an escaped representation.

When formatting string values (e.g., `const char*`, `std::string`, `fmt::string_view`, and their wide/Unicode variants as supported by the library), using a format specifier with `?` should produce an escaped form of the string content, consistent with how strings are escaped today when formatted as elements of a range.

Examples of expected behavior:
- `fmt::format("{:?}", "\n")` should format the string with the newline escaped (i.e., it should not emit an actual line break).
- `fmt::format("{:?}", "\"")` should escape quotes appropriately.
- The escaping behavior for control characters and backslashes should match the library’s existing range-string escaping rules.

The `?` presentation type must also interact correctly with alignment, fill, and width the same way as other string presentations do. In particular, width calculations must be based on the final escaped output length (not the unescaped input length) so that padding is correct. For example, formatting with both width/alignment and `?` (e.g., something like `"{:*^10?}"`) should produce an output of total width 10 where the escaped string is centered and padded with `*`.

If an argument type is not string-like, `?` should be rejected in the same way other invalid presentation types are rejected for that argument type (typically via a format-specification error).

Implement this so that escaped-string formatting is available outside of range formatting, while keeping existing range formatting behavior unchanged.