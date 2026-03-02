Using compile-time format strings via FMT_STRING currently rejects named arguments provided through the user-defined literal form (e.g., "foo"_a = value) in some supported configurations, even though these names are known at compile time and should be usable for compile-time checking.

The library should support statically named arguments with compile-time format strings, so that calls like:

```cpp
fmt::format(FMT_STRING("{foo}{bar}"), "bar"_a = "bar", "foo"_a = "foo");
"{foo}{bar}"_format("bar"_a = "bar", "foo"_a = "foo");
```

compile and format correctly (producing "foobar" with the values above), regardless of the order in which the named arguments are passed.

At the same time, dynamic named arguments created with `fmt::arg("name", value)` must remain disallowed with compile-time format strings. Attempting to use them with `FMT_STRING` should continue to fail at compile time with a clear diagnostic equivalent to:

```
static assertion failed: use statically named arguments with compile-time format strings: fmt::arg("name", value) -> "name"_a = value
```

In other words: compile-time format strings should accept only statically named arguments (such as those produced by the `_a` literal) and perform compile-time validation of the referenced names, while still rejecting dynamically named arguments produced by `fmt::arg`.