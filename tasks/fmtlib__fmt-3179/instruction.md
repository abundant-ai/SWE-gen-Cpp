Hexadecimal floating-point formatting in the library’s printf-style API is currently implemented by delegating to the system snprintf-family formatting. This causes inconsistent behavior across platforms/standard libraries and fails under stricter build configurations (notably when running C++17 builds on macOS), where hex-float formatting output and edge-case handling do not match the library’s expectations.

The printf-style formatting entry point fmt::sprintf should produce correct and stable output for hex-float conversions (the %a / %A specifiers) without relying on snprintf. In particular, formatting should be consistent across platforms for normal finite values, signed zero, and values that require exact hexadecimal exponent/mantissa rendering.

When calling fmt::sprintf with format strings that contain hex-float conversions, the output should:
- Match the expected hexadecimal floating-point representation for both lowercase (%a) and uppercase (%A) forms.
- Preserve the sign for negative zero (e.g., formatting -0.0 should include the minus sign in hex-float output where applicable).
- Correctly handle rounding/precision rules for the requested precision and default precision behavior.
- Correctly format special values (NaN and infinities) in a way consistent with the library’s overall formatting rules (and without platform-specific spellings or unexpected casing differences).

Currently, these cases can differ depending on the platform C library implementation used by snprintf, causing failures in printf-style formatting validation. Implement an internal hex-float formatter used by fmt::sprintf (and any shared float formatting logic it relies on) so that the behavior is deterministic and does not depend on snprintf.