Reusing a `simdjson::ondemand::document` across parses can produce a spurious error because the document keeps an old error state (“sticky error bit”). In particular, if a previous parse/iteration resulted in an error, later calls that reuse the same document may continue to report that prior error even when the new input is valid, or may report the wrong error for the new input.

This shows up when code does something like:

```cpp
simdjson::ondemand::parser parser;
simdjson::ondemand::document doc;

// First call sets an error state (for example, iterating an empty input)
auto err1 = parser.iterate(padded_string{""}).get(doc);

// Reuse the same doc for a different parse
auto err2 = parser.iterate(padded_string{"[1,2,3]"}).get(doc);
// Expected: err2 == simdjson::SUCCESS and doc can be used normally
// Actual (bug): err2 may incorrectly reflect the previous error state
```

Expected behavior: Each successful `parser.iterate(...).get(doc)` should leave `doc` in a clean state for reading, and the returned `simdjson::error_code` should reflect only the current parse. Reusing a `document` object should not require explicit destructor calls or reallocation just to clear prior errors.

Actual behavior: After an error has occurred once, subsequent reuse of the same `ondemand::document` can continue to carry that error, leading to failures even when parsing valid JSON or to incorrect error codes.

Fix the `simdjson::ondemand::document` reuse semantics so that assigning/overwriting a document as part of `parser.iterate(...).get(doc)` correctly resets all internal state, including any stored error code, so that later parses are not affected by earlier errors. Also ensure that parsing an empty input into a reusable document returns `simdjson::EMPTY` for that call, but does not poison subsequent uses of the same `document` object with a persistent `EMPTY` (or any other) error.