On macOS with OpenSSL support enabled, the library currently has logic to load trusted CA certificates from the Apple Keychain as part of SSL/TLS certificate verification. This behavior is effectively always compiled in on Darwin, which introduces two problems for downstream users:

1) Projects that enable OpenSSL support but do not want to link Apple Security/CoreFoundation frameworks (or cannot, e.g., due to cross-compiling, custom toolchains, or nonstandard build environments) may fail to build or link because Keychain-related symbols/frameworks are pulled in.

2) Users cannot opt out of Keychain-based certificate loading even when they prefer to supply their own CA bundle via OpenSSL configuration or explicit CA file/path settings.

Make “load CA certs from the Apple Keychain” an optional, compile-time feature controlled by a macro named `CPPHTTPLIB_USE_CERTS_FROM_MACOSX_KEYCHAIN`.

When `CPPHTTPLIB_USE_CERTS_FROM_MACOSX_KEYCHAIN` is defined (and OpenSSL support is enabled), the library should continue to use the macOS Keychain to populate the OpenSSL trust store as it does today.

When `CPPHTTPLIB_USE_CERTS_FROM_MACOSX_KEYCHAIN` is not defined, the library must:

- Compile cleanly on macOS with OpenSSL support enabled without requiring any Apple Security/CoreFoundation framework APIs.
- Not reference or call any Keychain/CoreFoundation/Security functions.
- Still allow TLS connections to work using OpenSSL’s normal trust mechanisms (e.g., user-provided CA file/path or OpenSSL defaults when available), without crashing or returning errors solely due to the Keychain feature being disabled.

In other words, Keychain certificate loading should be strictly opt-in via `CPPHTTPLIB_USE_CERTS_FROM_MACOSX_KEYCHAIN`; disabling it should remove the dependency on Apple frameworks and not break SSL/TLS functionality beyond the absence of Keychain-provided trust anchors.