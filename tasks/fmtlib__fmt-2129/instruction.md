The compile-time formatting API (used via `FMT_COMPILE`, `"..."_cf`, and `fmt::detail::compile<Args...>(...)`) does not fully match the runtime format-string parsing behavior for argument identifiers. In particular, compile-time compilation is missing correct support for:

- Manual argument indexing (e.g. `"{0} {1}"`)
- Named arguments in replacement fields (e.g. `"{name}"`)
- Correct compile-time detection of switching between automatic and manual indexing within the same format string (this should be rejected at compile time with a clear `static_assert` message, consistent with runtime rules)

As a result, users cannot rely on the compile-time API to parse and validate format strings that use `{0}` / `{1}` or `{name}`, and some format strings either fail to compile when they should work, or silently degrade into a runtime formatting path.

The compile-time parsing/compilation should be extended so that calling `fmt::detail::compile<Args...>("...")` (and the public compile-time wrappers that use it) can compile format strings containing both automatic indexing and manual indexing, and can also compile strings containing named fields when those named fields don’t require type-dependent format-spec parsing.

Expected behavior:

1) Manual indexing should work in the compile-time API exactly like in runtime formatting. For example, compiling a string like `"{0} {0}"` for an argument list including one integer type should succeed, and formatting with the compiled result should correctly reuse argument 0 in both places.

2) Named arguments without type-dependent specs should be supported in compile-time compilation. For example, `"{name}"` should be accepted when formatting is provided a named argument `fmt::arg("name", value)` (or equivalent), and the produced output should match runtime formatting.

3) Mixing automatic and manual indexing within the same format string must be diagnosed at compile time for compile-time compiled strings. For example, a format string that uses both `{}` and `{0}` should trigger a compile-time failure via `static_assert` with a message indicating that switching between automatic and manual indexing is not allowed.

4) Custom formatter parsing must still work with the compile-time compilation path. If a user type has a formatter with a custom `parse` function, compile-time compilation should correctly invoke/reflect that parsing logic as part of compilation (i.e., it shouldn’t regress compared to runtime formatting).

Current incorrect behavior that must be fixed:

- Compile-time compilation either fails to parse/compile strings containing `{0}` / `{name}` or fails to apply the same argument-id rules as runtime.
- Some unsupported cases attempt to fall back to runtime formatting via an `unknown_format()` result from the compilation procedure, but this fallback path is broken: attempting to use such a compiled format string either does not compile or does not behave like the runtime API.

The compile-time API should either (a) fully compile these formats, or (b) when compilation intentionally returns `unknown_format()` (e.g., for named arguments used with type-dependent format specs that cannot be resolved without compile-time name information), it must cleanly and correctly fall back to runtime formatting with the same observable results as calling the runtime formatting API directly.

Reproduction examples that should work after the fix:

```cpp
constexpr auto f1 = FMT_COMPILE("{0} {0}");
auto s1 = fmt::format(f1, 42);
// Expected: "42 42"

constexpr auto f2 = FMT_COMPILE("{name}");
auto s2 = fmt::format(f2, fmt::arg("name", 7));
// Expected: "7"
```

And an example that should fail at compile time:

```cpp
constexpr auto bad = FMT_COMPILE("{} {0}");
// Expected: compile-time failure with a static_assert message about
// mixing automatic and manual argument indexing.
```

Implement the missing compile-time parsing support and ensure the runtime-fallback behavior is correct for cases where compile-time compilation intentionally cannot proceed.