Building libzmq with CMake currently does not properly support enabling the GSSAPI security mechanism, even when the system has a working Kerberos/GSSAPI installation. As a result, users who configure with CMake cannot reliably build libzmq with GSSAPI enabled, and the GSSAPI-related security capability is not exposed consistently (including whether the GSSAPI security checks/tests are built).

The CMake-based build should provide a working option to enable/disable GSSAPI, detect the presence of a usable GSSAPI implementation, and link the correct libraries/flags when enabled. When GSSAPI is available and the option is enabled, libzmq should be compiled with the GSSAPI security mechanism enabled (the same way as in other supported build systems), and the build should also enable building the GSSAPI security verification program(s) that rely on this capability on non-Windows platforms.

Current problematic behavior:
- Configuring and building with CMake on a system with GSSAPI installed either fails at link time due to missing/incorrect GSSAPI link flags, or succeeds but does not actually enable GSSAPI support in the resulting libzmq build.
- The build system does not consistently expose a CMake-time capability flag indicating GSSAPI support (e.g., a ZMQ_HAVE_GSSAPI-style feature toggle), causing downstream logic to incorrectly include or exclude GSSAPI-related build targets.

Expected behavior:
- Users can enable GSSAPI when configuring with CMake (e.g., via an option such as enabling GSSAPI support).
- If GSSAPI is enabled and found, the library is built with GSSAPI support compiled in, and the build links against the required GSSAPI/Kerberos libraries.
- If GSSAPI is not found (or the option is disabled), the build should succeed with GSSAPI disabled and should not attempt to build or run GSSAPI-dependent components.
- On non-Windows platforms, when GSSAPI is enabled and available, GSSAPI security validation binaries/tests should be included in the standard set that gets built.

Provide a minimal reproduction example in the project’s CMake build workflow (configure + build) showing that enabling GSSAPI now results in a successfully linked build with GSSAPI support present, and disabling or lacking GSSAPI results in a clean build without GSSAPI targets.