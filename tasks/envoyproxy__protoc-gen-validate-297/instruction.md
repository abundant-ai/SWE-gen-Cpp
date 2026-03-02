String validation is missing support for two new well-known regex types for HTTP header field names and values, and C++ string UUID validation is not implemented.

1) HTTP header name/value well-known regex
When a string field is configured with `(validate.rules).string.well_known_regex = HTTP_HEADER_NAME`, validation should accept only RFC 7230-compliant header field names (tokens), with an additional allowance for an optional leading colon to support pseudo-headers. The pattern is:

"^:?[0-9a-zA-Z!#$%&'*+-.^_|~\u0060]+$"

Expected behavior:
- Values like "content-type", "x-envoy-upstream-service-time", and ":authority" are valid.
- Values containing spaces, invalid separators, or non-token characters are invalid.

When a string field is configured with `(validate.rules).string.well_known_regex = HTTP_HEADER_VALUE`, validation should reject ASCII control characters other than SP (space) and HTAB, consistent with RFC 7230 field-value constraints. The pattern is:

"^[^\u0000-\u0008\u000A-\u001F\u007F]*$"

Expected behavior:
- Values containing visible ASCII, spaces, tabs, and extended bytes (0x80-0xFF) are valid.
- Values containing NUL (\u0000), bare LF (\u000A), bare CR (\u000D), DEL (\u007F), or other disallowed control characters are invalid.

This should work consistently anywhere `well_known_regex` is supported.

2) C++ UUID validation
When a string field is configured with `(validate.rules).string.uuid = true`, C++ validation should be implemented (using RE2 for matching) so that a canonical UUID string passes and malformed UUIDs fail.

Expected behavior:
- Valid example: "f47ac10b-58cc-4372-a567-0e02b2c3d479"
- Invalid examples include wrong group lengths, missing hyphens, non-hex characters, or incorrect total length.

Current behavior:
- C++ UUID validation is missing/unimplemented, causing UUID-constrained fields to be treated as unsupported (or to not enforce validation), which results in either an "unimplemented" outcome or incorrect acceptance of invalid UUID strings.

After implementing these behaviors, validations should succeed/fail according to the regexes above and UUID constraints across the supported runtimes, with C++ no longer reporting UUID as unimplemented.