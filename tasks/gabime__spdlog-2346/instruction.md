When spdlog is compiled with `SPDLOG_USE_STD_FORMAT` on MSVC, formatting becomes significantly slower compared to using fmtlib. The slowdown is especially noticeable starting with spdlog 1.10.0, where formatting via `std::vformat()` allocates and returns a new string/buffer each time and appears to be particularly expensive in MSVC’s implementation.

The formatting path used by spdlog when `SPDLOG_USE_STD_FORMAT` is enabled should be changed to format directly into an existing buffer using `std::vformat_to()` rather than building a new buffer via `std::vformat()`. This should be done in a way that works across supported MSVC versions, because MSVC’s `std::format` implementation requires different ways of providing the formatting context depending on compiler version.

Concretely, code paths that currently do something like:

```cpp
memory_buf_t buf = std::vformat(fmt, std::make_format_args(std::forward<Args>(args)...));
```

should instead build an empty `memory_buf_t` and append into it via `std::vformat_to(...)`, e.g.:

```cpp
memory_buf_t buf;
// format into buf using std::vformat_to(...)
```

The implementation must ensure that formatting output is identical to before for all normal logging and filename/pattern formatting use cases (including formatting into `memory_buf_t` and converting buffers to string views/strings). It must also continue to behave correctly for runtime format strings (e.g. `SPDLOG_FMT_RUNTIME("...")`) and for error scenarios involving invalid format strings, where exceptions should still be thrown (and user-provided error handlers should still be triggered as before).

The goal is that building with `SPDLOG_USE_STD_FORMAT` no longer has the large performance regression on MSVC, while preserving existing spdlog formatting behavior and correctness across platforms/compilers.