`zmq_proxy_steerable()` currently lacks a properly licensed implementation and must be re-implemented in a clean-room way. The function is expected to run a steerable ZeroMQ proxy that forwards messages between a frontend socket and a backend socket, optionally capturing traffic to a third socket, while also accepting runtime control commands on a separate control socket.

The problem is that the existing behavior is either missing/blocked (preventing releases) or incorrect/incomplete compared to the expected semantics of a steerable proxy. As a result, applications that rely on `zmq_proxy_steerable(frontend, backend, capture, control)` cannot reliably start a proxy, steer it, and shut it down without hangs, incorrect forwarding, or control commands being ignored.

Implement `zmq_proxy_steerable()` so that it provides the following externally observable behavior:

- It continuously forwards all multipart messages from `frontend` to `backend` and from `backend` to `frontend`, preserving message boundaries and multipart structure.
- If `capture` is non-null, it must receive copies of forwarded messages (without preventing or altering delivery between frontend/backend).
- If `control` is non-null, the proxy must listen for control commands while proxying traffic. A control command to terminate the proxy must cause `zmq_proxy_steerable()` to return promptly, rather than blocking indefinitely.
- The proxy must be robust under concurrent client/worker activity: multiple DEALER clients and multiple ROUTER-side workers exchanging messages through the proxy should continue to make progress while control messages are processed.
- Shutdown must be clean: when the proxy is asked to terminate via the control socket, in-flight traffic should not cause the function to hang, and sockets using `ZMQ_LINGER = 0` should allow the test harness/application to exit without blocking.

Reproduction scenario that must work: create a ROUTER/DEALER proxy topology (clients connect to the proxy frontend, workers connect to the proxy backend), start `zmq_proxy_steerable()` in a background thread, run several clients sending requests and collecting responses from workers, and then send a terminate command via the proxy control socket. Expected result: requests and replies are correctly forwarded while running, and after the terminate command the proxy thread exits and `zmq_proxy_steerable()` returns.

If termination is requested and the proxy cannot exit, or if forwarding breaks multipart messages, drops replies, or ignores control traffic under load, that is a bug to fix.