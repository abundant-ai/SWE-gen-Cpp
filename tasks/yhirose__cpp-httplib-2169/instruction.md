When using cpp-httplib with SSL/TLS enabled (SSLClient/SSLServer), SSL handshake failures during nonblocking connect or accept cannot be inspected by the caller. The underlying OpenSSL return code and/or SSL error (from SSL_get_error) is computed inside the internal nonblocking handshake helper (the template function used for SSL connect/accept), but it is not exposed through the public API. As a result, after a failed connection/accept attempt, users can only see a generic failure (or an overly coarse httplib::Error value) and cannot determine whether the failure was due to WANT_READ/WANT_WRITE, SYSCALL, ZERO_RETURN, SSL protocol issues, certificate problems, etc.

This needs to be fixed so that after an SSL handshake failure, the caller can retrieve the relevant SSL error information from the Client/Server instance. In particular:

- If an SSL connection attempt fails (e.g., SSLClient connecting to a server with an incompatible certificate/CA, wrong SNI, protocol mismatch, etc.), the Client object should retain enough information about the last SSL handshake result so that user code can query it.
- If an SSL accept attempt fails on the server side (SSLServer accepting a client that fails handshake), the Server object should likewise retain the last SSL handshake result so it can be queried.

The exposed information must be sufficient to reproduce OpenSSL-style diagnostics, at minimum enabling callers to compute or directly obtain the equivalent of SSL_get_error(ssl, res) for the last handshake attempt. This should work for both connect and accept paths and specifically for the nonblocking handshake logic.

Expected behavior:

- After a failed SSL handshake during connect/accept, the library should provide a public way to retrieve the last SSL handshake result/error from the relevant Client/Server instance.
- The stored error should correspond to the most recent handshake attempt and be updated on each attempt.
- The value should allow users to distinguish common OpenSSL SSL_get_error categories (e.g., SSL_ERROR_WANT_READ/WRITE vs SSL_ERROR_SSL vs SSL_ERROR_SYSCALL vs SSL_ERROR_ZERO_RETURN), rather than only returning a single generic httplib::Error.

Actual behavior:

- SSL handshake failures occurring inside the nonblocking connect/accept helper are not accessible from Connect/Accept call sites, so the caller cannot obtain the OpenSSL SSL error for diagnostics.