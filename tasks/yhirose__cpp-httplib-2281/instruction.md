httplib::Client currently only supports progressive response-body reading via callbacks (e.g., a content receiver passed to Get/Post). This makes it difficult to build “pipe as you read” flows such as reverse proxies (read from an upstream Client and forward to a downstream Server chunked provider) without restructuring code into callback style.

Add a generator-like streaming API for Client responses that allows reading the response body incrementally in a pull model (iterator/generator style) using C++20 coroutines.

A caller should be able to do something conceptually like:

```cpp
httplib::Client cli(host, port);
auto res = cli.Get("/large-data");

std::string body;
while (res && res->has_data()) {
  body.append(res->data(), res->len());
  res->next();
}
```

The streamed response object must expose methods with these semantics:

- `has_data()` returns whether there is currently a data chunk available to read.
- `data()` returns a pointer to the current chunk bytes.
- `len()` returns the size of the current chunk.
- `next()` advances to the next chunk.

The API must work for large responses without requiring the entire body to be buffered in memory, and it must behave correctly with chunked transfer encoding.

Additionally, fix the streaming response header behavior to avoid emitting duplicate HTTP response headers in streaming scenarios. In particular, when a server endpoint returns a streamed response (such as `text/event-stream` with `Transfer-Encoding: chunked`), clients/proxies must not see duplicated header lines like:

```
Transfer-Encoding: chunked
Transfer-Encoding: chunked
```

or duplicated `Server`, `Access-Control-Allow-Origin`, or `Keep-Alive` headers. Duplicate header lines can cause reverse proxies like nginx to reject the upstream response with errors like:

```
upstream sent duplicate header line: "Transfer-Encoding: chunked", previous value: "Transfer-Encoding: chunked"
```

Expected behavior is that each header is emitted once (or combined appropriately where HTTP allows), and that streamed responses remain compatible with common proxies and clients.

The new streaming API should integrate with existing `httplib::Client` request methods (at minimum `Get`) and preserve existing behavior for non-streaming usage. Error cases should be representable the same way current request methods do (e.g., failed connection should not crash and should allow callers to detect failure).