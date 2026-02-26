When using the Bazel C++ proto toolchain ("cc_toolchain"), flipping the build setting "//bazel/toolchains:prefer_prebuilt_protoc" to True is supposed to make the toolchain use the full "protoc" binary (so that prebuilt protoc distributions can be used). Currently, even when this flag is enabled, the toolchain still ends up invoking the minimal compiler binary ("protoc_minimal" / "protoc_minimal_do_not_use"), which prevents prebuilt protoc support and causes the wrong compiler to be used in generated proto compilation actions.

Reproduce by building a target that compiles protos with the cc toolchain (a target that registers a "GenProto" action). Enable the build setting prefer_prebuilt_protoc. Inspect the argv of the "GenProto" action: it incorrectly contains a protoc_minimal-related path/string and does not point to the full protoc binary.

Expected behavior:
- If prefer_prebuilt_protoc is True, the "GenProto" action must invoke the full protoc executable. The argv should include a path ending with "/protoc" and must not include "protoc_minimal".

Actual behavior:
- With prefer_prebuilt_protoc enabled, "GenProto" still uses protoc_minimal (argv contains "protoc_minimal"), rather than switching to the full "protoc" binary.

Also ensure the default behavior is unchanged:
- If prefer_prebuilt_protoc is not set (or is False), the toolchain should continue to use protoc_minimal by default (argv contains "protoc_minimal").

Fix the toolchain configuration and/or protoc selection logic so that the prefer_prebuilt_protoc flag is respected during action construction, selecting full protoc only when the flag is True and leaving protoc_minimal as the default otherwise.