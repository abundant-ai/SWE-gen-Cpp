The library supports transparent HTTP body compression (request decompression and response compression) for several content codings, but it currently lacks support for Zstandard (zstd). As a result, clients and servers cannot correctly negotiate or handle `Content-Encoding: zstd` / `Accept-Encoding: zstd`, and attempts to use zstd compression either fail or fall back to uncompressed behavior.

Implement zstd support so that when zstd support is enabled at compile time, both client and server correctly encode and decode message bodies using Zstandard.

When a server receives an HTTP request with `Content-Encoding: zstd`, it should decompress the request body before handing it to handlers. If decompression fails (invalid/corrupted zstd payload), the request should be rejected with an appropriate client error rather than passing a garbled body to the handler.

When a client sends a request body with zstd encoding enabled, it should be able to compress the outgoing body and set `Content-Encoding: zstd` accordingly.

When a client advertises `Accept-Encoding: zstd` and the server is configured to serve compressed responses, the server should be able to return a response compressed with zstd and set `Content-Encoding: zstd`. The client should transparently decompress such responses so that `Response::body` contains the original uncompressed payload.

The implementation must interoperate with existing compression behavior: zstd must integrate into the existing content-coding selection logic (e.g., picking an encoding from `Accept-Encoding`), must not break existing gzip/deflate/brotli behavior, and must preserve correct handling of headers like `Content-Encoding`, `Accept-Encoding`, and `Content-Length` (e.g., do not report the uncompressed length as the transmitted length).

A minimal usage scenario that must work end-to-end:
- Start a `httplib::Server` with an endpoint that returns a known body (e.g., JSON).
- A `httplib::Client` requests the endpoint while advertising `Accept-Encoding: zstd`.
- The server responds with `Content-Encoding: zstd` and a zstd-compressed payload.
- The client returns a successful result where the response status is 200 and `Response::body` equals the original uncompressed body.

Additionally, request-body handling must work:
- A client sends a POST/PUT with a known body compressed with zstd and `Content-Encoding: zstd`.
- The server handler receives the decompressed body matching the original content.

This should be gated behind a compile-time option so projects without zstd available can still build without enabling it, while builds that enable the option gain full zstd functionality.