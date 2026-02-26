On toolchains that don’t support C++11 `noexcept`, the library’s portability macros for “non-throwing” functions are not being translated correctly, leading to compilation issues and/or incorrect exception specifications.

In particular, functions/destructors marked with the library’s `FMT_NOEXCEPT` macro are intended to be non-throwing. When compiling in an environment where `noexcept` is unavailable, these should instead use the old-style dynamic exception specification `throw()` so that the code remains valid C++ and matches the intended contract.

One concrete case is the destructor `OutputRedirect::~OutputRedirect()`, which is declared `FMT_NOEXCEPT` and calls `restore()` inside a `try`/`catch` to prevent exceptions from escaping. This destructor must compile cleanly and preserve the non-throwing guarantee across all supported compilers/standards, including ones without `noexcept`.

Fix the portability layer so that:

- If the compiler supports `noexcept`, `FMT_NOEXCEPT` expands to `noexcept` (or an equivalent modern form).
- If `noexcept` is not supported, `FMT_NOEXCEPT` expands to `throw()` (not an empty macro and not something that produces invalid syntax).

After the change, code using `FMT_NOEXCEPT` (including destructors and other functions declared as non-throwing) should compile without error in pre-C++11 mode / on compilers lacking `noexcept`, and the non-throwing intent should remain expressed in the function type.