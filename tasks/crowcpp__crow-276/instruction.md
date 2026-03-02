When starting a Crow application with an automatically assigned port (by calling `app.port(0)`), there is currently no reliable way to learn which port the server actually bound to after startup. This makes it difficult to run Crow in a background thread or in test environments where a free port must be chosen dynamically.

Crow should expose the final bound port from the application object after the server has started listening. For example, if a user does something like:

```cpp
crow::SimpleApp app;
app.port(0);
std::thread t([&] { app.run(); });

// After the server is listening, the app should be able to report the real port.
auto p = app.port();
```

Expected behavior: after startup, calling a public API on the app (e.g., a getter on the `App`/`SimpleApp` object) should return the actual port number assigned by the OS (a non-zero value). This returned value should match the port the underlying server is listening on, so clients can connect to `127.0.0.1:<returned-port>`.

Actual behavior: when `port(0)` is used, the app cannot report the assigned port (it either remains `0` or otherwise inaccessible), preventing programmatic discovery of the listening address.

Implement a public way to retrieve the bound port after calling `run()` (or equivalent startup) when `port(0)` was specified, ensuring it works when the server is started on a background thread and the value becomes available once the socket is bound and listening.