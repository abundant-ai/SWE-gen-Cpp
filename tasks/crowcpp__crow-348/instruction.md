Browser-based JavaScript clients cannot call Crow endpoints cross-origin because Crow does not provide proper CORS handling for preflight (OPTIONS) requests and for actual requests. When a frontend (e.g., running on http://myclient:3000) calls an API hosted on a different origin (e.g., http://myserver:5000) using fetch/XHR, the browser sends an OPTIONS preflight. Crow’s current behavior does not include the required CORS response headers, so the browser blocks the request with an error like:

"Response to preflight request doesn't pass access control check: No 'Access-Control-Allow-Origin' header is present on the requested resource."

Add a CORS middleware named crow::CORSHandler that can be registered on an app (e.g., crow::App<crow::CORSHandler>), and which automatically injects appropriate CORS headers into responses.

The middleware must allow configuring CORS rules via a fluent/builder-style API obtained from the app instance:

```cpp
auto& cors = app.get_middleware<crow::CORSHandler>();

cors
  .global()
    .methods("POST"_method, "GET"_method)
  .prefix("/cors")
    .origin("example.com")
    .headers("X-Custom-Header")
  .blueprint(bp)
    .ignore();
```

Required behavior:

1) By default, simply including crow::CORSHandler as middleware should enable CORS headers (so users do not need to implement their own OPTIONS handler just to avoid browser blocks).

2) For OPTIONS preflight requests to a route covered by a CORS rule, the response must include the expected CORS headers, including at least:
- Access-Control-Allow-Origin
- Access-Control-Allow-Headers
- Access-Control-Allow-Methods

3) For non-OPTIONS requests, the middleware must add the relevant CORS headers to the normal response as well (so that the browser accepts the response).

4) CORS rules must support:
- A global rule set via global()
- Rule sets that apply to a URL prefix via prefix("/...")
- Rule sets that can be attached to a blueprint via blueprint(bp)
- The ability to ignore/disable CORS for a blueprint via ignore()
- Setting allowed methods via methods(...) using Crow’s HTTP method literals (e.g., "GET"_method)
- Setting allowed request headers via headers("...")
- Setting an allowed origin via origin("...")

The main failure to address is that cross-origin fetch requests (especially those requiring preflight, like PATCH/PUT with JSON or custom headers) must stop being blocked by browsers when users register crow::CORSHandler and configure it as above.