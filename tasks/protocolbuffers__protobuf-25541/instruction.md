The Bazel configuration for selecting which protoc binary is used by the C++ toolchain is broken after moving prebuilt-related Bazel files into standard locations. The build is expected to support a boolean flag named `//bazel/flags:prefer_prebuilt_protoc` that controls whether the toolchain uses the full `protoc` binary or the minimal `protoc_minimal` binary.

Currently, when building a target that performs proto compilation via the C++ toolchain, the generated "GenProto" action does not reliably pick the correct protoc binary based on this flag. Two scenarios must work:

1) Default behavior (flag not set / false): the toolchain must use `protoc_minimal` for the GenProto action. The command line used for the GenProto action should include an argument/path containing `protoc_minimal`.

2) When `//bazel/flags:prefer_prebuilt_protoc` is set to true: the toolchain must use the full `protoc` binary instead of `protoc_minimal`. In this configuration, the GenProto action’s argv must include a protoc path that ends with `/protoc`, and it must not contain `protoc_minimal` anywhere.

This regression typically appears as either failing analysis of the GenProto action (wrong tool chosen) or inability to resolve/load the moved Bazel/Starlark definitions that wire the flag into toolchain selection. Fix the Bazel/Starlark configuration so that the flag label is correctly resolved from its standard location and the cc_toolchain’s protoc selection logic produces the expected GenProto argv in both configurations.