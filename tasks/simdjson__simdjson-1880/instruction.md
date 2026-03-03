Integer parsing via the ondemand API can incorrectly succeed on invalid JSON when the root element is a scalar (e.g., a number) and there is trailing non-whitespace content that is never validated.

For example, parsing a document created from strings like `"123[abc"`, `"123]abc"`, `"123{abc"`, `"123}abc"`, `"123,abc"`, or `"123 abc"` should fail because these are not valid JSON documents (they contain extra trailing content after a complete scalar value). However, calling `simdjson::ondemand::document::get_int64()` (and similarly `get_uint64()`) may return `123` without reporting an error for these cases. The error is only reliably reported for some trailing characters (e.g., `"123-abc"`).

This happens because, for scalar root documents, it is possible to read just the scalar token and never verify that the document ends immediately afterward.

When accessing a scalar root element through ondemand (e.g., using `ondemand::parser::iterate(...)` to obtain an `ondemand::document` and then calling `get_int64()` / `get_uint64()`), the implementation must validate that the scalar value is the only JSON value in the document (aside from allowed trailing whitespace). If any additional non-whitespace bytes remain after the scalar is consumed—such as structural characters (`[ ] { } ,`) or other non-space content—then retrieving the integer must report an error.

Expected behavior: the first attempt to evaluate `doc.get_int64().value()` (or `get_uint64().value()`) on inputs like `123[abc` or `123 abc` must throw/return an error indicating invalid JSON/trailing content.

Actual behavior: the call succeeds and returns `123` for some invalid trailing characters (notably whitespace and structural characters), allowing illegal JSON to be accepted.

Fix the ondemand scalar-root number parsing so that `get_int64` and `get_uint64` do not succeed unless the document contains exactly one top-level value and no trailing non-whitespace content.