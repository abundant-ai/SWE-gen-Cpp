Formatting a float argument is currently not distinguished from formatting a double in parts of the library, which causes two user-visible problems.

1) Custom argument formatting via fmt::arg_formatter cannot override float separately from double. If a user derives from fmt::arg_formatter and provides overloads like:

- operator()(double)
- operator()(float)

then calling fmt::vformat_to<CustomFormatter>(...) (or a wrapper that forwards through fmt::make_format_args) with a float value such as:

  na_format("{}", 4.f);

incorrectly dispatches to the double overload rather than the float overload. This makes it impossible to implement float-specific behavior (e.g., special-casing NaN/NA sentinels) distinct from double.

Expected behavior: when the formatted argument is of type float, the formatter dispatch should call CustomFormatter::operator()(float) (and similarly preserve other exact standard types).
Actual behavior: float arguments are treated as double for dispatch, so CustomFormatter::operator()(double) is called.

2) When shortest-roundtrip formatting is enabled (Grisu-based formatting), single-precision values are effectively formatted as if they were first promoted to double for the algorithm’s boundary calculations. As a result, formatting a float like:

  fmt::format("{}", 0.1f)

can produce a long decimal expansion such as:

  "0.10000000149011612"

instead of a short, single-precision-appropriate representation like "0.1".

Expected behavior: float formatting should use single-precision boundary calculations so that common values (e.g., 0.1f) round-trip correctly with a minimal representation appropriate for float, and float output should differ from double output when the underlying binary values differ.
Actual behavior: float output reflects double-style boundary handling, producing unexpectedly long strings for some float inputs.

Fix the float-vs-double distinction throughout the formatting pipeline so that (a) custom arg_formatter overload resolution correctly selects operator()(float) for float arguments, and (b) Grisu-based shortest formatting for float uses single-precision behavior rather than double behavior.