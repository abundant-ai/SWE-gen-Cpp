On some Linux distributions, the unversioned `python` executable is not available (only `python3` is provided). The project’s build/test tooling currently assumes it can invoke `python`, which causes configure/build/test steps that run Python scripts to fail with an error like `python: command not found`.

The build system should stop depending on an unversioned `python` binary and instead reliably use Python 3 discovered by CMake. When configuring with CMake, Python 3 must be located using `find_package(Python3 ...)`, and any custom commands/targets that run Python scripts must invoke the discovered interpreter via `${Python3_EXECUTABLE}`.

This needs to work in common scenarios:
- A system where `python` is missing but `python3` exists on PATH: configuration and subsequent build steps that call Python scripts should succeed.
- A system where Python 3 is installed but not on PATH (or a specific Python 3 should be used): setting CMake’s Python3 selection variables should cause the build to use that interpreter, and Python-invoking build steps should still run.

In particular, assembly-related build/test steps that post-process compiler output via a Python script must invoke Python through the CMake-discovered Python 3 executable rather than hard-coding `python`.