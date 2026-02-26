`fmt::MemoryWriter` currently can be used with `operator<<` for built-in/known streamable types, but it does not support streaming arbitrary user-defined types that only provide an `std::ostream` insertion operator. This prevents using `MemoryWriter` as a drop-in ostream replacement in codebases that rely on `operator<<(std::ostream&, const T&)`.

For example, given a type like `Date` (or `std::this_thread::get_id()`) that can be written to `std::ostream` via `operator<<`, the following should compile and append the textual representation to the writer:

```cpp
fmt::MemoryWriter w;
w << std::this_thread::get_id();
```

Expected behavior: streaming a value of any type `T` that is stream-insertable into `std::ostream` should write the same bytes that would be produced by `std::ostringstream oss; oss << value;` into the `fmt::MemoryWriter`. This should work for user-defined types, and also for streamable enums that intentionally are not treated as integers by fmt’s internal type conversion logic.

Actual behavior: attempting to stream such a user-defined type into `fmt::MemoryWriter` fails to compile because there is no matching `operator<<` overload (or the overload resolution does not route to the ostream-based formatting path that `fmt::format("{}", value)` already supports).

Implement support so that `fmt::MemoryWriter`’s streaming interface can accept streamable user-defined types (including enums with custom `std::ostream` output) and append their ostream-rendered text to the writer, consistent with `fmt::format("{}", value)` behavior for ostream-backed formatting.