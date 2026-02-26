When building {fmt} in fuzzing mode (with `FUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION` defined) using clang or gcc, fuzzing builds often add `-fno-exceptions`. In this configuration, parts of the formatting code still use direct exception throws (e.g., `throw std::runtime_error(...)` or other `throw` expressions) in fuzz-specific guards intended to prevent resource exhaustion (such as rejecting extremely large precision/width values).

With exceptions disabled, these direct `throw` sites cause compilation to fail. The library is expected to still compile in fuzzing mode with `-fno-exceptions` by routing all exception-like error signaling through `{fmt}`’s `FMT_THROW(...)` mechanism, which is designed to work correctly (or fail in a controlled/consistent way) depending on whether exceptions are enabled.

Fix the fuzzing-build compilation failure by ensuring that, when `FUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION` is defined, any error paths in formatting code that currently use raw `throw` (including fuzz-only resource-exhaustion checks) use `FMT_THROW` instead. After the change, a fuzzing build configured similarly to:

```sh
CXX=clang++
CXXFLAGS="-DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION= -fno-exceptions"
```

should compile successfully, and the fuzzing-mode guards should still trigger the same logical behavior (rejecting/aborting on unrealistic formatting requests rather than attempting huge allocations or extremely expensive work).