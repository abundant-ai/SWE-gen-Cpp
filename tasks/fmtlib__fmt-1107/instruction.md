Some functions in the project are intended to never return (they always throw or terminate), but they are not consistently annotated as such. This causes compilers and static analysis tools to treat them as potentially returning, which can lead to incorrect or noisy diagnostics (e.g., warnings about missing returns, unreachable code not being recognized, or control-flow analysis being less precise).

The library provides a macro for this purpose, `FMT_NORETURN`, and it should expand to an appropriate non-returning attribute (e.g., `[[noreturn]]` when available) and be applied consistently to functions that never return.

Fix the implementation so that:

- `FMT_NORETURN` reliably marks a function as non-returning on supported compilers/standards.
- Functions that unconditionally throw exceptions (for example functions like `throw_exception()` and `throw_system_error()` used by the project’s assertion helpers) are treated as non-returning by the compiler when declared with `FMT_NORETURN`.
- Code that relies on these functions being non-returning compiles cleanly without requiring extra dummy returns or workarounds.

A concrete scenario that must work: defining `FMT_NORETURN void throw_exception() { throw std::runtime_error("test"); }` and `FMT_NORETURN void throw_system_error() { throw fmt::system_error(EDOM, "test"); }` should compile without warnings about control flow, and tooling should understand that execution never continues past calls to these functions.