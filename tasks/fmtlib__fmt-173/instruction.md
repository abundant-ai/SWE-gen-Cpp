The formatting API should support named arguments in format strings, allowing users to reference arguments by name (e.g. "{name}") instead of only positional indices (e.g. "{0}"). Currently, using a name inside braces is not recognized as an argument reference and either formats incorrectly or triggers a format error, making it impossible to use named placeholders.

Implement named argument support in the `fmt::format` family (and any equivalent formatting entry points that accept a format string and a variadic argument list) such that:

- Placeholders of the form `{identifier}` look up an argument provided with the same name and format it with the given format specifiers.
- Named arguments can be mixed with positional arguments in the same format string (e.g. `"{0} {name}"`), and both should resolve correctly.
- Format specifiers must work with named arguments the same way they work with positional arguments (e.g. `"{name:>10}"`, `"{value:.2f}"`).
- If a placeholder references a name that was not provided, formatting should fail with a `fmt::FormatError` (or the library’s standard format exception type) indicating an unknown/missing named argument.
- If the placeholder syntax is invalid (e.g. malformed identifier, stray braces), existing error handling behavior should remain consistent (still throwing `fmt::FormatError`).

Example expected behavior:

```cpp
fmt::format("Hello, {user}!", fmt::arg("user", "world"))
// expected: "Hello, world!"

fmt::format("{greet}, {user}!", fmt::arg("greet", "Hi"), fmt::arg("user", "Alice"))
// expected: "Hi, Alice!"

fmt::format("{0} scored {points}", "Bob", fmt::arg("points", 42))
// expected: "Bob scored 42"

fmt::format("{missing}", fmt::arg("present", 1))
// expected: throws fmt::FormatError for missing named argument "missing"
```

This should work for both narrow and wide character formatting where applicable, and should not break existing positional-only formatting behavior.