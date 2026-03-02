Crow currently provides a Base64 encoder utility, but there is no corresponding Base64 decoder. This forces users to implement their own decoding logic when working with HTTP features that commonly use Base64 (for example, parsing Basic Authorization credentials, decoding tokens, or handling Base64-encoded payload fragments).

Implement a Base64 decoding function in the same public utility surface area where the existing Base64 encoder lives, so that users can round-trip values (encode then decode) using Crow-provided helpers.

When decoding, the function should:
- Accept standard Base64 input using the alphabet `A-Z a-z 0-9 + /`.
- Correctly handle `=` padding (0, 1, or 2 padding characters as appropriate).
- Reject invalid Base64 inputs (invalid characters, invalid length, malformed padding such as `=` appearing in the middle, or leftover non-zero bits in the final quantum) in a predictable way rather than producing silent garbage output.
- Correctly decode known simple cases, including:
  - `""` decodes to `""`
  - `"Zg=="` decodes to `"f"`
  - `"Zm8="` decodes to `"fo"`
  - `"Zm9v"` decodes to `"foo"`

The decoder should be consistent with the existing encoder’s behavior and types (for example, if the encoder works with `std::string`, the decoder should return decoded bytes as `std::string` as well). The API should be usable from typical Crow applications without requiring additional dependencies.

Additionally, where the project documentation/examples refer to returning HTTP status codes as raw integers, update them to use the appropriate status enum form instead (for example, using Crow’s status enum rather than a plain numeric status code), so example code aligns with the modern API style.