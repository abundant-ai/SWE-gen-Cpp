Building the library and its test suite on Windows using the MinGW toolchain currently fails due to incorrect assumptions about the Microsoft CRT and Windows-specific "secure" APIs. Code paths guarded only by `_WIN32` are being compiled under MinGW as if it were MSVC, but MinGW does not provide the same functions and behaviors (e.g., `strerror_s`, `fopen_s`, `_set_invalid_parameter_handler`, `_CrtSetReportMode`). As a result, compilation errors occur when these symbols are referenced, and some runtime expectations around error handling/assert suppression are incorrect under MinGW.

Fix MinGW support so that:

1) Retrieving system error messages works on MinGW.
When converting an `errno`/error code to a message string, MinGW builds must not require `strerror_s`. Calling the project’s helper that returns an error string for an integer error code should compile and return a non-empty message on MinGW, using the portable `strerror` behavior where appropriate.

2) Windows-only debug/assert suppression uses MSVC-only APIs.
Any functionality that suppresses Windows CRT assertions on invalid parameters (e.g., preventing crashes and allowing POSIX-like functions to return proper error codes) must only be enabled for the MSVC CRT. On MinGW, the same code must compile without including MSVC-only headers or calling MSVC-only functions.

3) File opening wrappers should not force MSVC’s `fopen_s` on MinGW.
Where the code conditionally replaces `fopen` with an MSVC-specific safe wrapper, that replacement must not be enabled on MinGW. MinGW builds should use the standard `fopen` without requiring `fopen_s`.

Overall expected behavior: the library and its tests compile successfully under MinGW on Windows, and the platform-specific branches correctly distinguish MSVC from MinGW (e.g., by treating `__MINGW32__` as a separate case from generic `_WIN32`).