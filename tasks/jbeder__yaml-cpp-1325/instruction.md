The YAML emitter does not currently support streaming `std::string_view` values. In C++17 builds, code like `YAML::Emitter out; out << std::string_view("Hello, std string view");` should emit the same YAML as if a string literal or `std::string` had been streamed, but today there is no matching `Emitter::operator<<(std::string_view)` overload (or it behaves incorrectly), preventing direct use of `std::string_view` with the emitter.

Add support for `Emitter::operator<<(std::string_view)` so that streaming a `std::string_view` scalar emits exactly the characters contained in the view, without requiring null-termination.

In particular, emitting a view that is a prefix of a larger buffer must only emit the prefix. For example:

```cpp
YAML::Emitter out;
out << std::string_view("HelloUnterminated", 5);
// expected emitted YAML: "Hello"
```

Also ensure that existing behavior remains unchanged:

- Streaming a string literal (e.g., `out << "Hello, World!";`) should still emit the literal.
- Streaming a `std::string` (e.g., `out << std::string("Hello, std string");`) should still emit its full contents.
- After emitting, `out.good()` should be true and `out.GetLastError()` should be empty for these successful cases.

Because this library must remain ABI compatible with C++11, adding `std::string_view` support must not require changing existing exported signatures in a way that breaks older consumers; the solution should provide a stable way for the emitter to write string data using an explicit pointer-and-length interface internally/externally as needed, while exposing the `std::string_view` streaming overload when compiled under C++17.