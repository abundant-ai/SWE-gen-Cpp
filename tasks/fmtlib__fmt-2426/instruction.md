`fmt::format_to` cannot currently be used during constant evaluation to format floating-point values into a fixed buffer, even when the format string is compiled with `FMT_COMPILE`. The goal is to make compile-time formatting work end-to-end (at least in header-only mode) so that code like:

```cpp
consteval auto make() {
  char out[32]{};
  fmt::format_to(out, FMT_COMPILE("{}"), 392.5);
  return out;
}
```

is valid and produces the expected characters at compile time.

Right now, attempts to format floating-point values in constant evaluation fail due to use of non-`constexpr` operations in the floating-point formatting pipeline (notably paths that rely on dynamically growing buffers / runtime-only functionality, and operations that are not permitted in constant evaluation). Integer/string compile-time formatting may work, but floating-point formatting does not.

Implement support so that, when constant evaluation is in effect, formatting via `fmt::format_to` with `FMT_COMPILE(...)` can format `float` and `double` values into a caller-provided character buffer without requiring runtime-only behavior.

The following behaviors must work in constant evaluation:

- Default formatting and common presentation types:
  - `FMT_COMPILE("{}")` with `0.0f` produces `"0"`
  - `FMT_COMPILE("{0:f}")` with `392.5f` produces `"392.500000"`
  - `FMT_COMPILE("{:}")` with `0.0` produces `"0"`
  - `FMT_COMPILE("{:f}")` with `0.0` produces `"0.000000"`
  - `FMT_COMPILE("{:g}")` with `0.0` produces `"0"`
  - `FMT_COMPILE("{:}")` and `FMT_COMPILE("{:g}")` and `FMT_COMPILE("{:G}")` with `392.65` produce `"392.65"`
  - `FMT_COMPILE("{:g}")` with `4.9014e6` produces `"4.9014e+06"`
  - `FMT_COMPILE("{:f}")` and `FMT_COMPILE("{:F}")` with `-392.65` produce `"-392.650000"`
  - `FMT_COMPILE("{0:e}")` with `392.65` produces `"3.926500e+02"`
  - `FMT_COMPILE("{0:E}")` with `392.65` produces `"3.926500E+02"`
  - `FMT_COMPILE("{0:+010.4g}")` with `392.65` produces `"+0000392.6"`

- Large magnitude formatting should be correct (no overflow/UB during formatting):
  - `FMT_COMPILE("{:f}")` with `9223372036854775807.0` produces `"9223372036854775808.000000"`

- Special values must be handled in constant evaluation:
  - For NaN (`std::numeric_limits<double>::quiet_NaN()`):
    - `FMT_COMPILE("{}")` produces `"nan"`
    - `FMT_COMPILE("{:+}")` produces `"+nan"`
    - If the platform/compiler reports a negative NaN via `std::signbit(-nan)`, then formatting `-nan` with `FMT_COMPILE("{}")` should produce `"-nan"`.
  - For infinity (`std::numeric_limits<double>::infinity()`):
    - `FMT_COMPILE("{}")` produces `"inf"`
    - `FMT_COMPILE("{:+}")` produces `"+inf"`
    - Formatting `-inf` with `FMT_COMPILE("{}")` produces `"-inf"`

Constraints/expectations:
- This compile-time floating-point formatting support is required at least when using `{fmt}` in header-only mode.
- The implementation must avoid calling functions that are not allowed during constant evaluation; constant evaluation should not require runtime I/O, locale-dependent operations, or non-`constexpr` allocations.
- `fmt::format_to` should still behave normally at runtime; the change should not break existing runtime formatting.

The end result should allow users to build `consteval`/`constexpr` helpers that return preformatted strings (written into a fixed-size char buffer) where floating-point arguments are formatted correctly under C++20 constant evaluation rules.