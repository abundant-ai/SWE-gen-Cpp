Crow currently lacks a reliable way to serve static files (especially over SSL) and can misbehave for larger files when using OS-level sendfile-style transmission: large files may not be fully sent and the connection can appear to hang until the server times out. Static file serving should work consistently for both HTTP and HTTPS connections.

Implement static file serving such that when a route is configured to serve a file from disk, Crow streams the file contents through the underlying ASIO socket in fixed-size chunks (around 16KB per read) and uses ASIO’s write operation to transmit each chunk. This behavior must be used for both non-SSL and SSL connections (i.e., avoid relying on sendfile() for HTTP only), so HTTPS static file serving works.

When serving a static file:
- If the requested file path does not exist (or cannot be opened), Crow must respond with HTTP 404 (not found) rather than timing out or returning an incorrect response.
- The response must include appropriate headers for static content, including a correct Content-Type based on the file extension (via the MIME type mapping) and a correct Content-Length matching the full file size.
- The full file content must be transmitted (no truncation) even for multi-megabyte files.

Additionally, the MIME type file generation utility should support passing arguments/options (so that MIME mappings can be generated/configured more flexibly), and those MIME mappings must be used when serving static files.

A minimal expected usage is that an application can register a route that serves an on-disk file (e.g., an image like a .jpg), and an HTTP client requesting that route receives a 200 response with correct headers and the file content; requesting a non-existent file returns 404.