`fmt::join()` currently only works for ranges where `begin()` and `end()` return the same type (i.e., the end value is an iterator). This breaks formatting for C++20 and range-v3 style ranges/adaptors where `end()` returns a *sentinel* type that differs from the iterator type.

Repro: given a range type where `auto it = range.begin()` returns an iterator and `auto last = range.end()` returns a different sentinel type, calling `fmt::format("{}", fmt::join(range, ", "))` fails to compile (typically due to template substitution failures when `join` assumes the end type is the same as the iterator, or when it tries to store/compare the end as an iterator type).

`fmt::join()` should accept such iterator/sentinel ranges and format them the same way it formats normal iterator ranges: it should iterate from `begin()` until reaching `end()` using `it != last` (or an equivalent valid sentinel comparison), and join each formatted element with the provided separator.

This change must not alter behavior for existing containers and ranges where the iterator and sentinel types are the same. Existing uses like `fmt::join(std::vector<int>{1,2,3}, ", ")`, tuple joining via `fmt::join(tuple, sep)`, and initializer-list joining must continue to produce the same output.

Expected behavior for sentinel ranges: formatting a sentinel-terminated range with `fmt::join(r, ", ")` should compile and produce output with the elements separated by the delimiter, with no trailing delimiter. Empty ranges should format as an empty string; single-element ranges should format as just the element.