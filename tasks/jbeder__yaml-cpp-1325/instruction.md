The YAML emitter currently supports streaming C-strings and std::string into an Emitter via operator<<, but it does not support std::string_view. In C++17 builds, attempting to emit a std::string_view either fails to compile (no matching Emitter::operator<< overload) or forces callers to convert to std::string, losing the efficiency benefits of non-owning string data.

Update the Emitter API to accept std::string_view via an overload:

```cpp
Emitter& Emitter::operator<<(std::string_view);
```

Emitting a string_view must write exactly the view’s contents, including when the view is not null-terminated. For example, emitting `std::string_view("HelloUnterminated", 5)` must produce the output `Hello` (and not read past the specified length).

The change must preserve a C++11-compatible ABI. Add a new low-level write entry point that takes a pointer and explicit size:

```cpp
void Emitter::Write(const char* data, size_t size);
```

Then ensure all relevant emitting paths that previously assumed null-terminated strings (or relied on std::string’s null termination) can route through the pointer+size form when appropriate, so that std::string_view emission is correct and does not overrun.

After emitting, the Emitter should still report a good() state and c_str() should match the expected YAML output for the emitted scalar.