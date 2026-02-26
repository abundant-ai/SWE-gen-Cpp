When building C++ proto targets with the provided Bazel toolchain, the default selection of the protoc binary is incorrect.

There is a boolean build flag `@protobuf//bazel/flags:prefer_prebuilt_protoc` that controls whether the toolchain should prefer a prebuilt/full `protoc` binary or fall back to the minimal one (`protoc_minimal`). The intended behavior is:

- If `prefer_prebuilt_protoc` is explicitly set to `False`, the C++ toolchain must use `protoc_minimal` for the `GenProto` action (the command line should include a path containing `protoc_minimal`).
- If `prefer_prebuilt_protoc` is not set (default configuration), the toolchain must use the full `protoc` binary (the command line should end with `.../protoc` and must not include `protoc_minimal`). In other words, the default value of `prefer_prebuilt_protoc` should behave as `True`.

Currently, under the default configuration the `GenProto` action ends up using `protoc_minimal` (or otherwise behaves as if `prefer_prebuilt_protoc` were `False`), which breaks the intended “prefer prebuilt/full protoc by default” behavior.

Fix the Bazel/Starlark configuration so that `prefer_prebuilt_protoc` defaults to `True` and the `GenProto` action in the C++ toolchain resolves to the full `protoc` binary by default, while still correctly switching to `protoc_minimal` when the flag is explicitly set to `False`.