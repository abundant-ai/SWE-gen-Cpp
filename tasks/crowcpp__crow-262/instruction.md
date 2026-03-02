Crow incorrectly accepts HTTP/0.9-style requests (requests that omit the HTTP version) even when they use methods that are not valid for HTTP/0.9. For example, when a client sends a request line like:

POST / HTTP/0.9-style (i.e., no version supplied)

Crow currently treats it as a valid request and continues processing, instead of rejecting it as a malformed/unsupported HTTP/0.9 request.

Crow should treat a request with no HTTP version as an HTTP/0.9 request, and for HTTP/0.9 it must only accept the GET method. If the request line has no version and the method is anything other than GET (e.g., POST), the server should reject the request and return an error response (rather than routing it normally).

Reproduction scenario: send a raw request without an HTTP version (no “HTTP/1.0” or “HTTP/1.1” token) using a non-GET method such as POST. Expected behavior: the request is rejected with an error response code (not a successful/normal routed response). Actual behavior: the request is accepted and handled as if it were a valid request.

Implement the correct protocol check in the request parsing/handling so that HTTP/0.9 requests are constrained to GET only, and ensure the server produces an error response when the constraint is violated.