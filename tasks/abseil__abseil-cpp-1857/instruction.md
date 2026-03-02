A buffer overflow can occur in Abseil’s internal C++ symbol demangling when parsing fails and the demangler attempts to roll back (backtrack) to an earlier output position. During this rollback, the code can write a null terminator to the output buffer without first verifying that the write is within the provided buffer bounds. This is triggered by malformed or partially valid Itanium-mangled names that force the demangler down a parsing path and then cause a failure requiring backtracking.

The demangling entrypoint `absl::debugging_internal::Demangle(const char* mangled, char* out, size_t out_size)` must never write outside `[out, out + out_size)`, including during parse rollback/backtracking paths. When `out_size` is small or when the demangler’s internal “rewind” logic restores an output pointer and then blindly writes `\0`, the function can overflow by writing the terminator out of bounds. The expected behavior is:

- `Demangle()` returns `false` for malformed mangled names (including cases where a template name is followed by malformed requires-clause encodings).
- Regardless of success or failure, `Demangle()` must not perform out-of-bounds writes; it must only write a terminator when there is space, and it must keep all internal output cursor/rollback operations consistent with `out_size`.

In addition, on AArch64 systems using pointer authentication (PAC), Abseil’s stack trace processing should actually apply the “hint space” instruction path that strips PAC bits from return addresses, matching the intended behavior described by existing comments. Currently, stack traces may include PAC-tagged return addresses, which can lead to incorrect symbolization or confusing/invalid addresses. The expected behavior is that captured return addresses used for stack traces are normalized by stripping PAC bits (using the intended hint-space mechanism) so that symbolization operates on canonical addresses.

Repro examples of inputs that must be handled safely include calls like:

```cpp
char tmp[100];
bool ok = absl::debugging_internal::Demangle("_Z3fooIiQEiT_", tmp, sizeof(tmp));
// This mangled name is malformed; ok must be false, and no memory outside tmp may be written.
```

Also, valid template/constraint encodings should still succeed, e.g. mangled names representing constrained templates should demangle successfully into a simplified form like `"foo<>()"` when there is sufficient output space.

Implementations should ensure both: (1) demangling rollback never writes beyond the output buffer, and (2) AArch64 stack trace return addresses are correctly stripped of PAC bits via the intended hint-space instruction behavior so that stack traces contain canonical addresses.