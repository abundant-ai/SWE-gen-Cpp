Named arguments created via the user-defined literal `_a` currently behave like runtime named arguments when used with the compile-time formatting API, because their argument names are not available as compile-time values. As a result, compile-time formatting cannot fully validate these named arguments (including name resolution and format-spec/type checks) the same way it can validate positional arguments, and it may fall back to a slower runtime path for named arguments with format specs.

Update the named-argument machinery so that `_a` produces a statically named argument type whose name is available at compile time, and ensure the compile-time formatting pipeline recognizes and uses this compile-time name.

After the change, these calls should compile to equivalent compiled formatting code (i.e., named arguments via `_a` should be zero-overhead vs positional arguments in the compile-time API):

```cpp
fmt::format(FMT_COMPILE("{0}"), 42);
fmt::format(FMT_COMPILE("{arg}"), "arg"_a = 42);
```

Additionally, compile-time checking should work for these statically named arguments exactly like it does for non-named arguments: when a compile-time format string references a named field, the name must be resolvable at compile time from the provided arguments, and type information must be available at compile time so that format specs for named arguments do not force a fallback to runtime formatting.

`fmt::arg(name, value)`-based named arguments should remain runtime-named (their names are not known at compile time), so they may retain overhead and not participate in compile-time name resolution.

Fix any `is_named_arg`-style type trait logic so that the new statically named argument type is correctly detected as a named argument by the library, and ensure the compile-time API can use it for name lookup and format-spec validation without triggering runtime fallback.