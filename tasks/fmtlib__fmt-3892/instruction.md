fmt currently can’t format `std::complex<T>` values, even though `std::complex` is a common standard-library numeric type and C++ provides complex-number literals via `std::literals`. Calling `fmt::format("{}", std::complex<double>(1, 2.2))` should produce the same representation as `operator<<(std::complex)` (as described on cppreference), but at the moment complex numbers are not formattable (typically resulting in a compile-time failure due to a missing formatter).

Add support for formatting `std::complex<T>` so that `fmt::format` accepts complex numbers and renders them in the standard stream-compatible form:

- `fmt::format("{}", std::complex<double>(1, 2.2))` should return `(1,2.2)`.
- Formatting should respect width/alignment applied to the overall complex value. For example, `fmt::format("{:>20.2f}", std::complex<double>(1, 2.2))` should right-align the full output to width 20, and apply the floating-point precision/format (`.2f`) to both the real and imaginary components, producing `"         (1.00,2.20)"`.

The formatter should work for standard floating complex instantiations such as `std::complex<float>`, `std::complex<double>`, and `std::complex<long double>`, including values created through complex literals (e.g., `using namespace std::literals; auto z = 1.0i;`).