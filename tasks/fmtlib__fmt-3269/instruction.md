Floating-point formatting in {fmt} produces incorrect results for some values when a small explicit precision is requested, and it can vary across compilers (notably Intel). A visible example is using printf-style formatting with a default %f precision: formatting the value 12.345 should yield the stable, correctly rounded output "12.345000", but on some builds it can produce "12.345001" (the last digit is off by 1). This indicates a rounding/digit-generation issue in the float-to-decimal conversion path.

The float formatting implementation needs to correctly generate digits and round according to the requested precision for fixed formatting (and generally for “small given precision” cases) so that the produced decimal representation is correctly rounded and consistent across compilers. In particular, when calling fmt::printf("%d:%d %f %s\n", 3, 1234, 12.345, "weekend"), the output must be exactly:

3:1234 12.345000 weekend

not "3:1234 12.345001 weekend".

This requires updating the internal float formatting routine (the logic that ultimately backs float/double formatting, including fmt::detail::format_float) to use a robust algorithm for cases with a small explicitly provided precision, ensuring correct rounding behavior and avoiding off-by-one errors in the last emitted digit. The implementation must still preserve correct behavior for special cases (such as zero, negative zero, infinities, and NaN), and it must not regress existing behavior for shortest-roundtrip formatting where precision is not specified.