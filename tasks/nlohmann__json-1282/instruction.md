Several exception messages produced by the library are currently missing important diagnostic details (byte position, line/column when available, and context around the error), and some specific error cases report unclear or misleading messages.

When parsing invalid JSON via `nlohmann::json::parse(...)`, `nlohmann::json::parse_error` exceptions should include more precise location information. In particular:

1) If a parse error can be tied to a position in the input, the error message should include the byte offset and, where possible, the line and column. The message should clearly indicate the location (e.g., “parse error at byte N” and additionally line/column information when it can be computed).

2) If parsing fails due to an unescaped control character inside a JSON string (for example, a literal newline or other control byte in the range 0x00–0x1F that appears without being escaped), the thrown `parse_error` message should explicitly state that the input contains an unescaped control character and provide the most specific location information available.

3) Error messages should include short context from the input around the failure location when available, so users can see what part of the JSON triggered the exception.

Separately, `nlohmann::json::json_pointer` construction currently produces incomplete diagnostics for invalid pointers.

- Constructing a JSON pointer from a string that does not start with `'/'` and is not empty must throw `nlohmann::json::parse_error` with id 107, and the message must include the byte location and the offending pointer text. For example:

```cpp
nlohmann::json::json_pointer p("foo");
```

must throw with exactly:

`[json.exception.parse_error.107] parse error at byte 1: JSON pointer must be empty or begin with '/' - was: 'foo'`

- Constructing a JSON pointer containing an invalid escape sequence using `'~'` must throw `nlohmann::json::parse_error` with id 108 and a clear message explaining that `'~'` must be followed by `'0'` or `'1'`. For example:

```cpp
nlohmann::json::json_pointer p1("/~~");
nlohmann::json::json_pointer p2("/~");
```

must throw with exactly:

`[json.exception.parse_error.108] parse error: escape character '~' must be followed with '0' or '1'`

The goal is to make the library’s diagnostics consistent and more actionable across these error conditions: parsing errors should report precise location (byte and, if possible, line/column), unescaped control characters should have a dedicated clear message, and messages should include input context when it can be produced.