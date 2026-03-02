`fmt::format_to` cannot currently be used in constant evaluation to format floating-point values into a caller-provided buffer, even when the format string is compile-time (e.g., produced via `FMT_COMPILE`). The goal is to support compile-time formatting (C++20 constant evaluation) for floating-point types when using the header-only configuration, so that code like `consteval/constexpr` helpers that call `fmt::format_to(char*, format, args...)` can compile and produce the expected output.

When `fmt::format_to` is invoked during constant evaluation with floating-point arguments (`float`/`double`), compilation fails because the floating-point formatting path relies on operations that are not permitted in constant evaluation (notably dynamically growing buffers / non-`constexpr` facilities). Integer and string formatting may already work in constant evaluation, but floating-point formatting does not.

After the fix, the following behaviors must work during constant evaluation (i.e., in a `consteval` function that writes into a fixed-size `char` array via `fmt::format_to`), using a compile-time format string:

- Default formatting:
  - Formatting `0.0f` with `{}` produces `"0"`.
  - Formatting `0.0` with `{:}` produces `"0"`.
  - Formatting `392.65` with `{:}` produces `"392.65"`.
- Fixed format:
  - Formatting `392.5f` with `{0:f}` produces `"392.500000"`.
  - Formatting `0.0` with `{:f}` produces `"0.000000"`.
  - Formatting `-392.65` with `{:f}` and `{:F}` produces `"-392.650000"`.
  - Formatting `9223372036854775807.0` with `{:f}` produces `"9223372036854775808.000000"`.
- General format:
  - Formatting `0.0` with `{:g}` produces `"0"`.
  - Formatting `392.65` with `{:g}` and `{:G}` produces `"392.65"`.
  - Formatting `4.9014e6` with `{:g}` produces `"4.9014e+06"`.
  - Formatting `392.65` with `{0:+010.4g}` produces `"+0000392.6"`.
- Exponent format:
  - Formatting `392.65` with `{0:e}` produces `"3.926500e+02"`.
  - Formatting `392.65` with `{0:E}` produces `"3.926500E+02"`.
- Special values:
  - For `nan` (from `std::numeric_limits<double>::quiet_NaN()`):
    - `{}` produces `"nan"`.
    - `{:+}` produces `"+nan"`.
    - For `-nan`, `{}` should produce `"-nan"` on platforms/compilers where `std::signbit(-nan)` is true during constant evaluation; otherwise behavior may be limited by compiler handling of negative NaN.
  - For `inf` (from `std::numeric_limits<double>::infinity()`):
    - `{}` produces `"inf"`.
    - `{:+}` produces `"+inf"`.
    - Formatting `-inf` with `{}` produces `"-inf"`.

This should be achievable without requiring runtime allocation during constant evaluation. The implementation must ensure that the floating-point formatting path used by `fmt::format_to` is valid in constant evaluation (C++20), at least for the above format specifiers and outputs, when used with a fixed-size output buffer provided by the caller.

The intended scope is compile-time formatting support; runtime behavior should remain consistent with existing formatting semantics.