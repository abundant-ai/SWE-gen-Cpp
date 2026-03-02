Applications handling large multipart/form-data uploads currently incur unnecessary memory usage because multipart parsing via crow::multipart::message stores an owned copy of the multipart payload even though the full raw body already exists in crow::request::body. This can effectively double memory consumption for large uploads.

Introduce a view-based multipart message/parser that can parse multipart/form-data without copying the request body data, instead keeping non-owning views into the original request body buffer. The new API should allow constructing/parsing a multipart message directly from a crow::request (or from the request body plus boundary) such that each part’s body and relevant metadata can be accessed without allocating/copying the underlying bytes.

The view-based multipart message must expose an interface largely compatible with the existing crow::multipart::message for iterating parts and reading each part’s fields (e.g., name, filename, headers) and content. However, because it stores non-owning views into the original request body, it must not be treated as safely returnable from a handler; the design should prevent or strongly discourage returning it from request handlers in a way that could outlive the request data and cause use-after-free.

Expected behavior:
- Parsing a multipart/form-data request should not copy the raw multipart payload bytes. Part bodies and header values should be accessible as non-owning views referencing the original request body storage.
- Typical multipart parsing operations (finding parts, reading per-part headers like Content-Disposition parameters such as name/filename, and accessing the part body) should continue to work for standard multipart messages.
- The view-based message should correctly handle multiple parts, including file parts with large bodies, without increasing memory usage proportional to the upload size beyond what is required for indexing/structure (e.g., vectors/maps of parts).

Actual behavior to fix:
- Constructing/using crow::multipart::message for multipart/form-data results in an additional owned copy of the request body, causing unnecessary memory overhead for large uploads.

The change should add the new view-based multipart message type (and any required lightweight string-view equivalent compatible with the project’s C++ standard), integrate it so users can parse multipart requests without copying, and ensure multipart functionality continues to behave correctly for normal request handling scenarios.