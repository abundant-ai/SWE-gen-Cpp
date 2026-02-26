Formatting and joining C++20-style ranges/views fails when the range’s `begin()`/`end()` are not `const`-qualified (common for views). In these cases, `fmt` currently assumes it can iterate a range through a `const` reference, so attempting to format or join such a range does not compile.

For example, given a `std::vector<int> ints{0,1,2,3,4,5};` and a view pipeline like:

```cpp
auto even = [](int i){ return 0 == i % 2; };
auto square = [](int i) { return i * i; };

auto filtered    = ints | std::views::filter(even);
auto transformed = filtered | std::views::transform(square);
```

both of the following should compile and work:

```cpp
fmt::print("{}\n", filtered);
fmt::print("{}\n", fmt::join(filtered, ","));
```

Currently these usages fail to compile because `fmt` cannot obtain iterators from ranges whose `begin/end` are only available on non-`const` objects.

Update range formatting and `fmt::join` so that they support ranges where `begin/end` are not callable on `const` objects. This must work for typical C++20 views produced by `std::views::filter` and `std::views::transform`.

Additionally, range iteration should not rely solely on member `begin()`/`end()`; it should also work when `begin(r)`/`end(r)` are found via argument-dependent lookup (ADL), while still correctly handling C arrays.

After the change, formatting existing supported ranges (arrays, nested arrays, `std::vector`, nested vectors, `std::map`, `std::pair`, and tuples) must continue to produce the same output format as before (e.g., vectors formatted like `{1, 2, 3}`, maps formatted like `{("key", value), ...}`, tuples like `(a, b, c)`), and the new view/range cases must compile and format consistently with other ranges.