Formatting floating-point `std::chrono::duration` values does not correctly apply the format precision in chrono format strings. This appears as a regression compared to older versions.

When formatting a floating-point duration such as:

```cpp
std::chrono::duration<double, std::nano> a{46.666667};
```

using chrono duration formatting:

```cpp
fmt::format("{}", a);
fmt::format("{:.0}", a);
fmt::format("{:.1}", a);
fmt::format("{:.2}", a);
fmt::format("{:.0%Q}", a);
```

the precision should control rounding of the numeric quantity (`%Q`) of the duration, not produce incorrect rounding or ignore the duration quantity.

Current incorrect behavior includes cases where precision `0` rounds to the wrong value. For the example above, formatting with `"{:.0}"` and `"{:.0%Q}"` currently yields `"50ns"` and `"50"` respectively, but it should round to `"47ns"` and `"47"`.

More generally, for `std::chrono::duration<double, std::milli> dms(1.234)`, applying precision should format the quantity with the requested decimal places:

```cpp
fmt::format("{}", dms)      // expected: "1.234ms"
fmt::format("{:.2}", dms)   // expected: "1.2ms" (precision applied to the numeric quantity)
```

However, precision formatting for floating-point durations currently fails to apply floating-point formatting semantics to the duration’s count, producing output that does not represent the time quantity correctly.

Implement support for precision in chrono duration formatting so that:
- Precision in `"{:.N}"` affects the formatted duration quantity (with rounding consistent with floating-point formatting).
- Precision in `"{:.N%Q}"` affects the formatted numeric quantity only.
- The unit (`%q` / default unit suffix) remains correct and is not affected by numeric precision except for rounding-driven changes to the displayed number.
- Precision `0` rounds correctly for floating-point duration representations (e.g., 46.666667ns -> 47ns / 47 for `%Q`).