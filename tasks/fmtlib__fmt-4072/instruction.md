Formatting values of Clang’s `_BitInt(N)` types fails with fmt v10+ during compile-time format-string processing, even though it worked in fmt 9.x.

On Clang versions that support `_BitInt` (notably Clang >= 14), calling fmt formatting APIs with a `_BitInt` argument (e.g. `fmt::format("{}", value)` or equivalent formatting through `fmt::print`) triggers a compilation error in the constexpr format-argument description logic:

```
error: constexpr variable 'desc' must be initialized by a constant expression
```

This happens because `_BitInt` arguments aren’t recognized/mapped cleanly as a supported integral argument type in the internal type-mapping used to build the constexpr argument descriptor. As a result, the code path that encodes argument types for compile-time formatting cannot form a valid constant expression.

The library should treat `_BitInt` (and unsigned `_BitInt`) as supported integer types on Clang compilers that implement the feature (enablement should be limited to Clang >= 14). After the fix, formatting a `_BitInt` value should compile and behave like formatting any other integer: it should select the correct integral formatting category (signed vs unsigned) and work in both compile-time-checked format strings and runtime format strings.

In particular, ensure the internal argument type mapping used by the formatting context can unambiguously match `_BitInt` inputs (including reference-qualified forms), so that building the constexpr argument-type descriptor succeeds and doesn’t produce the constant-expression initialization failure.