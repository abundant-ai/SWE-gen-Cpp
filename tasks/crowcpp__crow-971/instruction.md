Building Crow against newer Boost.Asio versions (e.g., Boost 1.87) can fail because the code still uses deprecated Asio APIs that are removed/disabled in modern configurations. A common failure is a compile error like: "namespace boost::asio has no member io_service". This happens when Crow code refers to legacy types and functions such as `asio::io_service` and older address parsing APIs (e.g., `asio::ip::address::from_string`).

Crow should compile cleanly when deprecated Asio APIs are unavailable (for example when compiling with `ASIO_NO_DEPRECATED`, or with Boost.Asio versions where `io_service` is removed). In particular:

- Any Crow API surface and internal components that currently depend on `asio::io_service` must work with `asio::io_context` instead.
- Any code paths that construct IP addresses from strings must work without `asio::ip::address::from_string`, using the non-deprecated equivalents.

After the change, typical usage that relies on an Asio event loop like `asio::io_context` (including creating sockets/endpoints using `asio::ip::make_address(...)` and connecting a `asio::ip::tcp::socket`) should compile and function normally with both standalone Asio and Boost.Asio builds.