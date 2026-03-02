Creating a `crow::multipart::message` from an incoming HTTP request can crash (segmentation fault) when the request uses `Content-Type: multipart/form-data` but the `boundary` parameter is missing, empty, or malformed. This happens in real clients when they forget to set the full multipart Content-Type header, resulting in a header like `multipart/form-data` with no `boundary=...` value.

Reproduction scenario: a handler receives a request with a `Content-Type` header set to `multipart/form-data` (no boundary parameter) and then constructs `crow::multipart::message multipart_message(req);`. Instead of rejecting the request safely, Crow can dereference invalid data during multipart parsing and segfault.

`crow::multipart::message` should fail safely for invalid multipart requests. Specifically:

- If the `Content-Type` header indicates `multipart/form-data` but the boundary parameter is missing, `crow::multipart::message` construction must not crash and must throw an exception indicating the boundary could not be found.
- If the boundary parameter exists but is empty (e.g. `boundary=`), `crow::multipart::message` construction must not crash and must throw an exception indicating the boundary is empty.
- If the boundary parameter exists but does not match the actual boundary markers present in the body, `crow::multipart::message` construction must not crash and must throw an exception indicating the boundary is invalid/mismatched.

Expected behavior: constructing `crow::multipart::message` from such requests should reliably throw (e.g., `std::runtime_error` or another documented exception type used by Crow) rather than causing undefined behavior or a segmentation fault. Valid multipart requests with a correct non-empty boundary should continue to parse successfully.

Example of problematic request header:

```http
Content-Type: multipart/form-data
```

Example of malformed header:

```http
Content-Type: multipart/form-data; boundary=
```

Example of mismatch: header specifies one boundary, but body uses a different boundary delimiter; this should be detected and reported via an exception during multipart parsing.