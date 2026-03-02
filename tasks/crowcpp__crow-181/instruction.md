Crow currently lacks a first-class way to modularize routes into reusable groups with a shared URL prefix and per-group configuration, similar to Flask’s “blueprints”. This makes it difficult to build larger applications by composing independent sub-applications (e.g., an “admin” module under /admin, an “api” module under /api) without manually repeating prefixes and re-wiring route registration.

Add Flask-style Blueprint support so that routes can be registered against a blueprint object and then mounted onto an application with an optional URL prefix. When a blueprint is registered on an app, every route defined on that blueprint must become reachable on the app under the blueprint’s prefix, while preserving the route’s original path, HTTP method constraints, and handler signature support.

Concretely, the API should allow:

- Creating a blueprint with a name (or identifier) and optionally a base prefix.
- Defining routes on the blueprint similarly to defining routes on an app (the same kinds of handler overloads should work, including handlers that take no arguments and handlers that take a `const crow::request&`).
- Registering/mounting a blueprint onto an app (e.g., `SimpleApp`) so its routes are available.
- Supporting an additional prefix at registration time (so a blueprint can be mounted under different prefixes in different apps or multiple times).

The routing behavior must match normal Crow routing semantics after registration:

- Exact vs trailing-slash behavior must be preserved (e.g., a route defined as `/file` should not match `/file/`, and a route defined as `/path/` should match `/path/` while `/path` should behave consistently with Crow’s existing rules).
- Parameterized routes must continue to work (e.g., routes containing typed parameters like `<int>`, `<uint>`, `<double>`, `<str>`, `<path>`), with parameters extracted and passed to handlers as they would be for routes registered directly on the app.
- `app.validate()` must succeed when all blueprint routes have valid handlers, and must fail (throw) for missing/invalid handlers in the same way as direct routes.

Registering a blueprint must not break existing non-blueprint apps or route registration; applications that don’t use blueprints should behave exactly as before.

If the blueprint mechanism supports per-blueprint middleware/hooks, they must be isolated to the blueprint and applied only to requests routed to that blueprint; however, even without middleware support, the core requirement is correct route grouping + mounting + prefixing with identical routing/validation behavior to direct app routes.