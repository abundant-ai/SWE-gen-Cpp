When logging a null-terminated C string (const char*), the logger currently copies the entire string into an internal raw buffer before formatting and writing. This causes unnecessary allocations/copies and slows down logging, especially for large C strings.

Update the logging pipeline so that logging a C string can avoid copying the message content into the raw buffer. Introduce support in the core log message representation (the object passed through sinks/formatters) to optionally store the message as a non-owning fmt::string_view pointing directly at the provided C string. When this view is present, it must be treated as the authoritative message payload used for formatting (e.g., %v) and output instead of the raw buffer.

Also add support for an additional logging call for C strings where the caller already knows the length or where the input may not be null-terminated. This API should accept a pointer plus an explicit size and log exactly that number of characters.

Expected behavior:
- Calling logger.info("Hello") must log exactly "Hello".
- Calling logger.info("") must log an empty message.
- Logging std::string values must continue to behave as before.
- Numeric logging (e.g., logger.info(5) and logger.info(5.6)) must continue to produce the same textual output.
- Log-level filtering must still work: if the logger’s level is set above info, an info message must not be emitted.

The optimization must not change the observed output compared to the existing behavior; it should only change how the message is carried internally to avoid the copy. The non-owning view must be used safely: the logged message should remain correct and stable for the duration of the logging call and through formatting/writing, without reading past the provided buffer (especially for the pointer+size overload).