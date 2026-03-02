Floating-point formatting with a small, explicitly provided precision produces incorrect decimal output in some cases, and can be compiler-sensitive. In particular, formatting a value like 12.345 with a default fixed precision of 6 (e.g., via printf-style formatting using "%f") is expected to produce exactly "12.345000", but on some toolchains (notably Intel), the library can produce "12.345001" instead. This indicates a rounding/digit-generation error in the float-to-decimal conversion path used when a small precision is requested.

The formatting implementation needs a dedicated algorithm for the “small given precision” case that correctly generates digits and rounds according to the requested precision, producing stable results across compilers. The problem occurs in the internal float formatting routine (commonly referred to as `format_float`) which is responsible for generating the decimal digits and exponent information used by higher-level fixed/scientific selection. When the caller provides an explicit precision (as opposed to requesting the shortest round-trip representation), the digit generation and rounding must ensure that the final rendered decimal string matches the mathematically correct rounding for that precision.

Reproduction example:

```cpp
#include <fmt/printf.h>
int main() {
  fmt::printf("%d:%d %f %s\n", 3, 1234, 12.345, "weekend");
}
```

Expected output:

```
3:1234 12.345000 weekend
```

Actual output observed on some toolchains:

```
3:1234 12.345001 weekend
```

The updated behavior should ensure that:
- For fixed formatting with an explicit small precision (including the default precision used by "%f"), the last printed digit is correctly rounded and does not drift by 1 ulp at the last digit.
- The result is deterministic across compilers and does not depend on extended precision or incidental floating-point register behavior.
- The existing behavior for “shortest round-trip” formatting (when precision is not explicitly provided and the implementation selects the minimal digits that round-trip) remains correct and unaffected.

If the formatting code uses cached tables/constants for Dragonbox/decimal conversion, those tables must be consistent with the new algorithm so that the digit-generation path remains correct for all relevant exponents, including boundary cases that require the maximum cached exponent range.