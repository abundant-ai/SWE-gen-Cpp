The library currently does not provide a public, correct way to URL-encode user-provided text that is intended to be embedded into a request path or query parameter. As a result, constructing a path that contains reserved characters (e.g. an ampersand `&`) and passing it to `httplib::Client::Get` can lead to incorrect requests and unexpected server responses.

For example, building a path like:

```cpp
httplib::Client cli("https://openapi.tidal.com");
std::string path = "/v2/searchresults/Piri Tommy Villiers - on & on/relationships/tracks";
auto result = cli.Get(httplib::append_query_params(path, {
  {"include", "tracks,tracks.artists,tracks.albums"},
  {"countryCode", "DE"},
}));
```

should allow the user-input portion (`"Piri Tommy Villiers - on & on"`) to be encoded so the server receives the correct path segment (with `&` represented as `%26`). Without encoding, the server can interpret the path incorrectly and return empty/incorrect results.

The library has an internal URL-encoding routine (`httplib::detail::encode_url`), but it is not publicly accessible for users constructing paths, and it also does not encode all characters that should be percent-encoded. In particular, control characters like tab (`'\t'`) are not encoded (it should become `%09`), which can cause requests to fail when such characters appear in user-provided input.

Add a public helper for encoding URL components (for use in path segments and/or query values) so users can safely encode arbitrary user input before composing the full URL and using `httplib::append_query_params` and `httplib::Client::Get`.

Expected behavior:
- Provide a public API (e.g. `httplib::encode_url_component(...)` or equivalent) that percent-encodes URL components correctly.
- The encoding must at minimum encode reserved characters like `&` when used as data, and must percent-encode control characters such as tab (`'\t'` -> `%09`).
- The produced string must be compatible with `httplib::append_query_params` and usable in `httplib::Client::Get` paths without double-encoding.

Actual behavior:
- There is no public way to encode user input for path construction.
- The existing internal encoder does not encode some characters (e.g. `\t`), and unencoded reserved characters like `&` in path data lead to incorrect server behavior.
