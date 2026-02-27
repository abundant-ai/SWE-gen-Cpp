Building libzmq on Windows toolchains that are not MSVC (notably MinGW) fails or behaves incorrectly because the code uses the presence of `_MSC_VER` to decide whether Windows-specific IPC/AF_UNIX support headers should be used. MinGW targets Windows but does not define `_MSC_VER`, so logic like “if MSVC then include/use Windows AF_UNIX support, else assume non-Windows/POSIX” ends up skipping required Windows headers (e.g. `afunix.h`) and can cause compilation errors or missing IPC functionality.

The platform decision must not be based on `_MSC_VER`. Instead, Windows-specific code paths (including whether to include `afunix.h` when IPC is enabled) should be selected based on whether the build target is Windows, i.e. `ZMQ_HAVE_WINDOWS` (and any existing feature guards such as `ZMQ_HAVE_IPC`), rather than on the compiler.

Reproduction scenario: compile libzmq with MinGW on Windows with IPC enabled. Expected behavior is that Windows builds with `ZMQ_HAVE_WINDOWS` use the Windows networking/IPC header set and compile successfully (including AF_UNIX support where available), regardless of whether the compiler defines `_MSC_VER`. Actual behavior is that MinGW builds incorrectly follow non-Windows branches and fail to compile or omit Windows IPC support.

Fix all occurrences where `_MSC_VER` is used as a proxy for “Windows” so that:
- Windows-only includes/definitions are gated by `ZMQ_HAVE_WINDOWS` (and `ZMQ_HAVE_IPC` where relevant), not `_MSC_VER`.
- Non-Windows builds continue to use the POSIX headers/paths.
- The code compiles and IPC-related behavior is consistent across MSVC and MinGW when targeting Windows.