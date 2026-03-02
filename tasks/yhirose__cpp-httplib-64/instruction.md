The HTTP server/client API is missing complete REST method support. Users can register handlers for GET and POST, but cannot properly implement a RESTful interface that uses additional HTTP verbs such as PUT and DELETE. This prevents building endpoints like `PUT /resource/:id` or `DELETE /resource/:id` using the library’s normal routing/handler mechanism, and also prevents clients from issuing these requests through the high-level client API.

Add first-class support for at least the PUT and DELETE methods across the public API. On the server side, users should be able to register handlers for these methods similarly to existing ones (e.g., analogous to `Get(...)`/`Post(...)`), and the server should correctly dispatch incoming requests with method `PUT` or `DELETE` to the corresponding handler based on the request path.

On the client side, users should be able to send PUT and DELETE requests with the same ergonomics as existing GET/POST calls, including:

- PUT: ability to send a request body (and related headers like `Content-Type` / `Content-Length`) and receive a `Response`.
- DELETE: ability to send a DELETE request (with headers; and if the API pattern supports bodies for other methods, it should behave consistently here as well) and receive a `Response`.

When a PUT/DELETE request is made to a server that has a matching handler, the handler should run and the response should be returned to the client. When there is no matching handler for a supported method/path, the behavior should be consistent with existing methods’ “no route” handling (e.g., returning the same kind of not-found or method-not-allowed response the library uses elsewhere), rather than silently failing or being treated as an unsupported/unknown method.

The implementation must ensure that request parsing recognizes the method tokens "PUT" and "DELETE" and that any internal method checks, routing tables, or dispatch logic include these methods so that they behave identically to existing methods in terms of matching, handler invocation, and response generation.