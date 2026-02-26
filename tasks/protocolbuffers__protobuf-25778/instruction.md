The Bazel configuration flag `@protobuf//bazel/flags:prefer_prebuilt_protoc` is intended to control whether builds use the full `protoc` binary by default or fall back to the `protoc_minimal` binary. The default behavior is currently wrong for consumers who rely on the flag being enabled by default: when the flag is not explicitly set, proto compilation may still select `protoc_minimal` (or otherwise behave as if “prefer prebuilt protoc” is disabled).

When building a target that generates C++ code from a `proto_library` using the `//:cc_toolchain`, the compile action named `GenProto` must select the correct `protoc` binary based on this flag:

- When `@protobuf//bazel/flags:prefer_prebuilt_protoc` is **unset** (i.e., the user does not set it in the build invocation), the build should behave as if the flag is **True**. In this default case, the `GenProto` action must use the full `protoc` binary, with an argument path that ends in `"/protoc"`, and it must not use or reference `protoc_minimal`.

- When `@protobuf//bazel/flags:prefer_prebuilt_protoc` is explicitly set to **False**, the build must use `protoc_minimal` for the `GenProto` action (the argv should contain a path matching `*protoc_minimal*`).

Currently, the selection logic does not correctly treat the unset case as True, leading to the wrong protoc binary being used by default. Update the flag default and any related selection logic so that the default (unset) behavior uses full `protoc`, while explicitly setting the flag to False still forces `protoc_minimal`.