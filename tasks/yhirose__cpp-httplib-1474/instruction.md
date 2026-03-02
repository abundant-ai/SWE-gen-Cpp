On macOS, HTTPS client connections that rely on the system trust store cannot currently use the macOS Keychain as a source of CA certificates. As a result, when a user enables OpenSSL support and expects the library to trust the same root CAs that the OS trusts, certificate verification can fail unless the user manually supplies a CA bundle (e.g., via a file path or explicit CA data). This differs from the behavior on Windows where system certificates can be used.

Add support on macOS to load the system CA certificates from the macOS Keychain and feed them into the TLS configuration used by the client so that standard public HTTPS endpoints validate successfully without requiring a user-provided CA bundle.

The expected behavior is:
- When OpenSSL support is enabled and certificate verification is enabled, the client should be able to validate server certificates using the macOS system trust store (Keychain) when no explicit CA bundle has been configured by the user.
- The behavior should be analogous to the existing Windows “load system certs” behavior: it should populate OpenSSL’s trust store (or the SSL context) with certificates obtained from the OS.
- If loading from the Keychain is unavailable or fails, the library should fail gracefully (e.g., keep existing behavior and report failure via the existing return value/error mechanism used for system cert loading).

Ensure this feature is actually usable in typical macOS builds:
- Building and linking on macOS must include the necessary Apple frameworks (Security and CoreFoundation) so that the new Keychain-loading code links correctly.

After the change, a user should be able to create an HTTPS client, enable peer verification, and connect to a public site with a certificate chain anchored in system roots without providing a CA file, and the handshake should succeed on macOS.