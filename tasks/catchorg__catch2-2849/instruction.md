Catch2’s text wrapping logic incorrectly counts ANSI color escape sequences as visible characters and can split escape sequences across wrapped lines. This breaks column wrapping for colored diagnostic output (e.g., from a matcher’s describe output) and can also corrupt formatted output when long, colorized text is printed.

When a string containing ANSI SGR color codes (e.g., "\x1b[31m" … "\x1b[0m") is wrapped to a fixed column width, the wrapping should be based on the visible text width only. ANSI escape sequences must not contribute to the measured column width, and they must never be split in the middle by the wrapping/hyphenation logic.

Add support in the text flow/wrapping API so that a column can be constructed from an ANSI-aware string type and then streamed/written with correct wrapping. In particular:

- Introduce and expose a type named `Catch::TextFlow::AnsiSkippingString` that represents a string possibly containing ANSI SGR escape sequences.
- Update `Catch::TextFlow::Column` so it can operate on such ANSI-aware input during wrapping (including indentation and hyphenation behavior) without counting ANSI escape bytes toward line width.
- Ensure wrapping preserves the original ANSI sequences in output, but never breaks an escape sequence across lines. Escape sequences should be treated as “zero-width tokens” that move with the surrounding text.

Correctness requirements:

- For plain text without ANSI codes, wrapping behavior must remain unchanged.
- For text containing ANSI SGR sequences, the wrapped output must match what would be produced if the same text were wrapped with the escape sequences removed (in terms of where line breaks occur), except that the escape sequences remain present in the output.
- If a wrap would otherwise occur in the middle of an ANSI sequence, the wrap must be moved so the sequence remains intact.
- Existing behaviors must still work: respecting already-present newlines, respecting configured width, respecting indentation (`indent`, `initialIndent`), and splitting long words with hyphenation when the width is very small.

Example scenario: given a `Column` with width 10 containing text where some words are wrapped in color codes, the output should wrap at the same visible boundaries as the uncolored version and should not display broken escape sequences (e.g., stray `[` or partial `\x1b[` fragments) on either line.