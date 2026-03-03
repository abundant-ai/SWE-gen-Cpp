When the process global locale is set to a non-"C" locale (e.g. via `std::locale::global(std::locale(""))` with `LC_ALL=en_US.UTF-8`), YAML emission of numeric scalars incorrectly uses locale-specific formatting. For example, emitting the integer `2112` can produce `2,112` under `en_US.UTF-8` or `2.112` under `nl_BE.UTF-8`. This output is not valid plain integer YAML in many parsers: `2,112` is parsed as a string ("2,112"), and `2.112` may be interpreted as a floating-point value.

The emitter must produce locale-independent YAML scalars by default. Specifically, any internal `std::stringstream` (or equivalent stream) used for producing YAML output should be imbued with the classic "C" locale so that integers and floating-point values are formatted using `.` as the decimal separator and without thousands separators, regardless of the process global locale.

Reproduction example:

```cpp
std::locale::global(std::locale(""));
YAML::Emitter out;
out << 2112;
std::cout << out.c_str() << "\n";
```

Expected behavior: the output for `2112` is `2112` (no grouping separators), and more generally numeric output is stable and independent of `LC_ALL` / the global C++ locale.

Actual behavior: the emitted scalar can include locale-specific separators (e.g. `2,112` or `2.112`), changing the YAML meaning.

Implement the fix so that the default behavior of `YAML::Emitter` (and any other YAML emitting/serialization APIs that rely on stringstreams) uses the "C" locale for output formatting, even if the user changes the global locale. This should cover both integers and floating-point values and should ensure consistent emission for nodes and emit helpers that serialize scalars through streams.