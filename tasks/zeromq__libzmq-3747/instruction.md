Building libzmq for Universal Windows Platform (UWP) fails to compile when IPC support is enabled. IPC integration introduced recently causes UWP builds to try to compile or reference IPC-specific code paths that are not supported on UWP, leading to compilation errors. Before IPC support was introduced, UWP builds used the non-IPC eventing path (e.g., the wepoll-based select/poll mechanism) and compiled successfully.

The library should compile successfully on UWP with default configuration, even when IPC is generally available on other Windows targets. On UWP specifically, IPC must be treated as unavailable at build time so that IPC-related code is not compiled and the runtime transport/poller selection falls back to the non-IPC behavior.

Reproduction: configure/build libzmq for a UWP target with IPC enabled (or with IPC auto-detected as enabled) and attempt to compile. The build should succeed; currently it fails during compilation because UWP cannot build IPC-related pieces.

Expected behavior: a UWP build completes without compilation errors and uses the same effective behavior as before IPC was introduced (IPC disabled on UWP, falling back to the standard Windows polling backend).

Actual behavior: enabling (or auto-enabling) IPC causes the UWP build to attempt to compile unsupported IPC integration and fail.

Fix requirement: adjust the platform feature gating so that UWP is recognized as not supporting IPC, and ensure the IPC transport/integration is excluded from compilation on UWP and does not get selected/registered for that target. The public build configuration should reflect IPC as disabled on UWP so downstream users do not inadvertently enable it and break the build.