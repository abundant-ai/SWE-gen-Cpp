Crow’s catchall handler currently does not receive enough information to distinguish which routing error occurred. In particular, when an incoming request does not match any route, Crow will invoke the catchall only for a 404 Not Found case. For other routing-related errors such as 405 Method Not Allowed, Crow falls back to its default handling and does not invoke the catchall. As a result, applications cannot centralize error handling for both “no route” and “wrong method” cases, and even if catchall were invoked, the handler would not reliably be able to tell which error occurred.

Update Crow’s catchall behavior so that it is invoked for both 404 (no matching route) and 405 (route exists but HTTP method not allowed) scenarios, and ensure the response status code is set appropriately before the catchall is called. The catchall handler must be able to inspect the status via `crow::response::code` and see 404 for not-found requests and 405 for method-not-allowed requests.

Example of expected behavior:
- If a request targets an unknown path, Crow should call the catchall and the `crow::response` seen by the catchall should have `res.code == 404`.
- If a request targets a known path but uses a method that is not registered for that route, Crow should call the catchall and the `crow::response` seen by the catchall should have `res.code == 405`.

Currently, 405 does not go through catchall, and/or the status code observed by the catchall is not set to the correct error code. After the change, developers should be able to implement a single catchall that branches on `res.code` to customize the response for 404 vs 405.
