The HTTP client currently does not properly support the CONNECT method, which is required to establish an HTTP tunnel through a proxy (commonly for HTTPS proxying). When users attempt to issue a CONNECT request using the client API, the library either cannot construct/send a valid CONNECT request or does not handle the expected CONNECT response semantics, preventing tunnel establishment.

Implement proper CONNECT method support on the client side so that a CONNECT request can be issued in the same way as other methods and results in a correct request line and handling of the response.

Expected behavior:
- The client must be able to send a request with method "CONNECT".
- The request target for CONNECT must support the standard form used for tunneling (e.g., "host:port" rather than a path like "/").
- A successful tunnel establishment response (typically HTTP 200) should be treated as success by the client call, returning a valid response object with status set (e.g., 200).
- Non-success statuses (e.g., 403, 407) should be surfaced as normal HTTP responses (not as malformed-request errors), allowing callers to inspect status/headers/body.

Actual behavior to fix:
- CONNECT requests cannot be performed reliably using the client API (either rejected as an unsupported method, serialized incorrectly, or handled in a way that prevents interpreting a 200 response as successful tunnel establishment).

Reproduction example (conceptual):
- Create a client pointing at an HTTP proxy endpoint.
- Issue a CONNECT request targeting an origin server (e.g., "example.com:443").
- The call should succeed and report status 200 when the proxy allows tunneling; currently it fails or behaves incorrectly.

Update the relevant client request/response handling so CONNECT is treated as a first-class HTTP method like GET/POST, while also respecting CONNECT’s request-target format requirements for tunneling.