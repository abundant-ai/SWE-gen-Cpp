When the process is running under a non-"C" locale (e.g., after calling `std::locale::global(std::locale(""))` and having `LC_ALL=en_US.UTF-8` or `LC_ALL=nl_BE.UTF-8`), yaml-cpp’s YAML output incorrectly formats numeric scalars using locale-specific thousands separators and decimal punctuation.

For example, the following program:

```cpp
int main(){
  std::locale::global(std::locale(""));
  YAML::Emitter out;
  out << 2112;
  std::cout << out.c_str() << "\n";
}
```

can emit `2,112` under `en_US.UTF-8` and `2.112` under `nl_BE.UTF-8`.

This output is not valid as an integer scalar in a portable way: `2,112` is parsed as a plain string (`"2,112"`) by yaml-cpp, and `2.112` may be interpreted as a floating-point value by other YAML parsers. The same locale-sensitive formatting can affect other numeric emissions performed through yaml-cpp’s output pipeline.

Numeric emission must be locale-independent and follow the YAML expectations regardless of the user’s global locale. In particular:
- Emitting integer values (e.g., streaming `2112` into `YAML::Emitter`, and emitting numeric scalars from `YAML::Node`/conversion paths) must produce `2112` with no thousands separator.
- Floating-point emission must use `.` as the decimal separator and must not introduce locale-specific grouping.
- These guarantees must hold even if the application has set a non-"C" global locale via `std::locale::global`.

Implement this by ensuring that any `std::stringstream` (or equivalent standard iostream formatting machinery) used internally to generate YAML text is imbued with the classic "C" locale so that numeric formatting is stable and not affected by environment locale settings. The change should cover all code paths that format scalars for output so that locale-dependent punctuation cannot leak into emitted YAML.