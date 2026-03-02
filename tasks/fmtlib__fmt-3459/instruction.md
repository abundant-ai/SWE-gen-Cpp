On macOS (Apple Clang 14.x) and MSVC when compiling in C++20 mode, compile-time formatting with `FMT_COMPILE` fails for some floating-point formats because a non-`constexpr` math function is used during constant evaluation.

A representative failure looks like this (Apple Clang 14.0.3, C++20):

```
error: call to consteval function 'test_format<...>' is not a constant expression
note: non-constexpr function 'ceil' cannot be used in a constant expression
    std::ceil((f.e + count_digits<1>(f.f) - 1) * inv_log2_10 - 1e-10));
```

The formatting library performs a `ceil` operation as part of its floating-point formatting/precision logic (in the `fmt::detail` floating-point code path). In C++20, `std::ceil` is not required to be `constexpr` (it becomes `constexpr` in C++23), and in practice Apple Clang and MSVC do not constant-evaluate `std::ceil` here, so any `consteval`/compile-time formatting instantiation that reaches this code path fails to compile.

Expected behavior: In C++20, formatting a floating-point value using compile-time format strings should still be usable in constant evaluation when the library’s compile-time formatting facilities are used, e.g. something like:

```cpp
auto s = test_format<11>(FMT_COMPILE("{0:f}"), 392.5f);
// expected: "392.500000"
```

This should compile successfully under Apple Clang and MSVC in C++20 mode and produce the same formatted output as at runtime.

Actual behavior: The compilation fails because `std::ceil` is invoked in a context that must be a constant expression.

Fix the floating-point formatting implementation so that the `ceil` computation used by the compile-time formatting path is `constexpr`-friendly in C++20 across major compilers (Apple Clang/MSVC/GCC). The change should preserve existing runtime behavior and output formatting, while allowing the compile-time formatting instantiations that currently fail to compile to become valid constant expressions again.