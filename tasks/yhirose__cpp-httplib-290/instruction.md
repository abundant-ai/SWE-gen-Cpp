`httplib::Client` currently doesn’t provide a way to force outbound connections to use a specific local network interface/address. This is a problem on multi-homed machines (e.g., multiple NICs / multiple ISP links): users need to choose which interface the TCP connection originates from, but `httplib::Client` always lets the OS pick the source address.

Add support for selecting the outgoing interface on the client side by introducing a `set_interface` method on `httplib::Client` (and any other relevant client types, e.g. SSL client variants if applicable). After calling this method, subsequent requests made by that client instance must bind the underlying socket to the specified local interface/address before connecting to the remote host.

Expected behavior:

- Users can call something like:
  ```cpp
  httplib::Client cli("example.com", 80);
  cli.set_interface("192.168.1.10");
  auto res = cli.Get("/");
  ```
  and the TCP connection should originate from the provided local address/interface (i.e., the client socket is bound to that local endpoint prior to `connect`).

- Passing an empty string (or otherwise “unset” state) should restore the default behavior (no forced binding; OS chooses the interface).

- If the provided interface/address cannot be used (invalid address format, address not present on the host, bind fails, etc.), the request should fail cleanly (no crash/hang). The failure should be observable via the existing `httplib::Client` error signaling (e.g., null response / false return, and the appropriate `Error` value if the API exposes it).

- The setting should be per-client-instance and persist across multiple requests made with the same client object.

- This should work for both HTTP and HTTPS client connections if the library supports both.
