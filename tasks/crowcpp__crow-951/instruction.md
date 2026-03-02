Crow’s automatic handling of HTTP OPTIONS requests needs to support a configurable return status code.

Currently, when an OPTIONS request is handled automatically (for example, for CORS preflight or when Crow generates a default OPTIONS response for a route), the server returns a fixed success status. Some deployments require returning HTTP 204 (No Content) for preflight responses, while others expect HTTP 200 (OK). This should be selectable at build time via a CMake option.

Add a CMake configuration option that controls what status code Crow uses for these automatic OPTIONS responses:
- When the option is enabled, the OPTIONS response status must be 204.
- When the option is disabled (default), the OPTIONS response status must be 200.

The change must affect the actual HTTP response produced by Crow when receiving an OPTIONS request (i.e., the status line must be either `HTTP/1.1 200 OK` or `HTTP/1.1 204 No Content` accordingly). The behavior should be consistent across the relevant code paths that generate OPTIONS responses (including CORS/preflight handling and any default OPTIONS handling Crow performs).

Example scenario: sending a raw request like:

`OPTIONS /some/route HTTP/1.1\r\nHost: 127.0.0.1\r\n\r\n`

should yield a response whose status code matches the configured option (200 by default, 204 when enabled).