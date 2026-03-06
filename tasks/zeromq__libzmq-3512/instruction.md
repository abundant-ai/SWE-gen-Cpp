There are inconsistencies and duplicated/conditionally-available APIs around socket monitoring, particularly the monitoring “pipes stats” functionality. Applications that build against libzmq can end up with mismatched behavior depending on build flags: some builds expose monitoring stats symbols or declarations but do not provide consistent runtime behavior, and other builds unnecessarily hide functionality behind ifdefs even when it should be available.

The monitoring API must behave consistently for invalid inputs and unsupported transports:

- Calling `zmq_socket_monitor()` with a non-`inproc://` endpoint (for example `"tcp://127.0.0.1:*"`) must fail and set `errno` to `EPROTONOSUPPORT`.

- When the optional monitoring stats API is available (`zmq_socket_monitor_pipes_stats()`):
  - Calling `zmq_socket_monitor_pipes_stats(NULL)` must fail with `errno` set to `ENOTSOCK`.
  - Calling `zmq_socket_monitor_pipes_stats(socket)` on a valid socket that does not have monitoring enabled must fail with `errno` set to `EINVAL`.

Additionally, the public API surface should not contain duplicated declarations/definitions for the same monitoring/stats functionality. There should be a single, unambiguous exported API for socket monitor pipes stats (when enabled), with consistent compile-time visibility and link-time/runtime behavior.

Fix the library so these calls return the correct errors in the scenarios above and ensure the monitoring/stats APIs are not duplicated or inconsistently gated by unnecessary conditional compilation.