The library provides printf-style formatting helpers such as fmt::fprintf for writing formatted output to C FILE* streams. There is currently no corresponding overload that allows writing formatted output directly to a C++ std::ostream, which makes it inconsistent with the rest of the API and forces users to format to a string first and then stream it.

Add an overload of fmt::fprintf that accepts a std::ostream& as the output target and writes the formatted result into that stream.

The new overload should behave like the existing fmt::fprintf for FILE*:

- It must accept a printf-style format string and any number of arguments.
- It must format using the same printf-formatting rules and error handling as the existing fmt::sprintf/fprintf family.
- It must write the formatted characters to the provided std::ostream (respecting the stream’s state; if the stream is in a bad/fail state, the write should not succeed).
- It must return a result consistent with fprintf-style APIs: the number of characters written (or, if the stream cannot be written to, an appropriate failure result consistent with the library’s conventions).

Example usage that should work:

```cpp
std::ostringstream os;
auto n = fmt::fprintf(os, "answer = %d", 42);
// os.str() should be "answer = 42"
// n should equal the number of characters produced
```

The overload must be available via the same namespace and name (fmt::fprintf) without breaking existing overload resolution for FILE* or other existing fprintf variants.