cpp-httplib currently supports HTTPS primarily through OpenSSL-compatible TLS. This makes it difficult to use in embedded or cross-compiled environments where OpenSSL may be unavailable or undesirable, and where mbedTLS is often the standard TLS stack.

Add an abstract TLS API so that HTTPS functionality in cpp-httplib can be provided by different TLS backends. The library must support at least these TLS providers:

- OpenSSL (existing behavior)
- MbedTLS (new optional backend)

When TLS support is enabled, users should be able to create and use `httplib::SSLClient` for HTTPS requests as they do today. The behavior should not depend on the backend: requests should succeed the same way, including common HTTPS behaviors such as redirects, proxy usage, and authentication flows.

The build-time configuration must allow selecting the TLS provider via preprocessor macros:

- Defining `CPPHTTPLIB_OPENSSL_SUPPORT` should enable the OpenSSL TLS backend.
- Defining `CPPHTTPLIB_MBEDTLS_SUPPORT` should enable the MbedTLS TLS backend.
- When either backend macro is enabled, the library should consider TLS available (i.e., `CPPHTTPLIB_SSL_ENABLED` should be defined consistently) so that `SSLClient`-gated code is enabled.

If neither `CPPHTTPLIB_OPENSSL_SUPPORT` nor `CPPHTTPLIB_MBEDTLS_SUPPORT` is defined, TLS must be treated as disabled: `httplib::SSLClient` functionality should not be available/compiled, and HTTP-only behavior should continue to work.

A CMake consumer must also be able to request TLS support via components such that selecting an MbedTLS component results in the appropriate macro being defined for consumers (so that `find_package(httplib REQUIRED COMPONENTS MbedTLS ...)` enables `CPPHTTPLIB_MBEDTLS_SUPPORT` similarly to how an OpenSSL component enables `CPPHTTPLIB_OPENSSL_SUPPORT`).

Expected behavior examples:

- With `CPPHTTPLIB_MBEDTLS_SUPPORT` defined and linked against mbedTLS libraries, constructing `httplib::SSLClient cli("nghttp2.org");` and calling `cli.Get("/httpbin/get")` should perform an HTTPS request (subject to network conditions) without requiring any OpenSSL headers or symbols.
- Code that is conditionally compiled under `#ifdef CPPHTTPLIB_SSL_ENABLED` must compile and run regardless of whether the TLS backend is OpenSSL or MbedTLS.
- Proxy and redirect behavior should work the same way for `httplib::Client` (HTTP) and `httplib::SSLClient` (HTTPS) when TLS is enabled; for example, using `set_proxy(...)` and `set_follow_location(true)` should not regress under the MbedTLS backend.

The main problem to solve is that cpp-httplib needs a backend-agnostic TLS interface and corresponding build integration so that enabling MbedTLS support provides a fully functional `SSLClient` implementation and `CPPHTTPLIB_SSL_ENABLED` behavior equivalent to the existing OpenSSL-based HTTPS support.