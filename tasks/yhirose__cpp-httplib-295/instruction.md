The library currently exposes a `timeout_sec` value as a constructor parameter (e.g., when creating an HTTP client object). This API has proven problematic because it forces timeout configuration to be fixed at construction time and makes it harder to adjust timeouts dynamically or in code paths where the client must be default-constructed first.

Update the public API so that `timeout_sec` is no longer accepted by the constructor. Instead, provide a `set_timeout_sec` method that can be called after construction to configure the timeout in seconds.

After this change:

- Code that previously constructed a client with a `timeout_sec` argument should no longer compile; the constructor overload taking `timeout_sec` must be removed.
- A client constructed without a timeout parameter must allow timeout configuration via `set_timeout_sec(...)`.
- The configured timeout must actually affect request behavior the same way the old constructor parameter did (i.e., it must be used by the underlying connection / read-write / request logic wherever the timeout is enforced).

Expected behavior examples:

```cpp
httplib::Client cli("localhost", 1234);
cli.set_timeout_sec(5);
// requests made by cli should now use a 5-second timeout
```

If `set_timeout_sec` is called multiple times, the most recent value should be used for subsequent requests.

The change should be applied consistently to the relevant client types (including any SSL/TLS variants if present) so that timeout configuration works uniformly across them.