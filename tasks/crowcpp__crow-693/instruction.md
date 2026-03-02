WebSocket connections created through Crow cannot currently specify or negotiate a subprotocol during the handshake. This causes interoperability problems with some clients (e.g., browser/JS WebSocket libraries) that send a `Sec-WebSocket-Protocol` header in the upgrade request and expect the server to respond with a `Sec-WebSocket-Protocol` header selecting one of the requested protocols. Without this response header, the client may immediately close the connection.

Crow’s WebSocket handshake implementation needs to support setting `Sec-WebSocket-Protocol` on the handshake response when the application chooses a subprotocol.

The server should allow the user to configure the subprotocol to return as part of the WebSocket upgrade response. When the client’s handshake request includes `Sec-WebSocket-Protocol: proto1, proto2, ...`, Crow should be able to return `Sec-WebSocket-Protocol: <selected-proto>` on the 101 Switching Protocols response (where `<selected-proto>` is chosen by the application).

Expected behavior:
- If the application specifies a subprotocol (e.g., "chat"), the handshake response must include `Sec-WebSocket-Protocol: chat`.
- If the application does not specify a subprotocol, Crow must not add a `Sec-WebSocket-Protocol` header to the handshake response.
- The selected protocol should be one of the protocols offered by the client (comma-separated list in the request header). If the client did not offer the selected protocol, Crow should not claim it in the response.

Provide an application-facing way to set the handshake subprotocol on WebSocket routes/handlers (i.e., a public API that can be used when defining a WebSocket endpoint) so that users can ensure browser clients don’t close the connection due to missing/incorrect `Sec-WebSocket-Protocol` negotiation.