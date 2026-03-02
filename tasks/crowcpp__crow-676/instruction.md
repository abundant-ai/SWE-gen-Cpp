When defining routes in a Crow application, conflicting routes (e.g., registering two handlers for the same path) are currently not detected until late in the lifecycle (often when calling `run()`), where an exception like `"handler already exists for /page1"` is thrown. This makes debugging difficult when routes are registered in multiple places.

Crow provides `validate()` to check the routing setup, but `crow::Crow` (and `SimpleApp`) currently behaves as if `validate()` is a one-time operation: once `validate()` has been called, adding additional routes does not reliably allow re-validation because internal state (e.g., a “validated” flag) prevents validation from running again, and/or `validate()` performs non-idempotent setup work that should not be repeated.

Update the routing/application lifecycle so that `validate()` can be called multiple times safely and deterministically, and so it performs only validation of the current routing state (including detection of conflicting/duplicate route registrations). In particular:

- If a user calls `app.validate()`, then later adds or modifies routes, calling `app.validate()` again must re-check the routing table and detect conflicts based on the updated set of routes.
- Calling `validate()` multiple times without adding new routes should not break routing behavior and should not perform non-validation side effects multiple times.
- Conflicting route definitions such as:
  ```cpp
  CROW_ROUTE(app, "/page1")([]{ return "Hello world 1"; });
  CROW_ROUTE(app, "/page1")([]{ return "Hello world 2"; });
  ```
  should be detectable via `validate()` (so users can force earlier detection before `run()`), and repeated calls to `validate()` should continue to catch such conflicts after any subsequent route registrations.

Additionally, rule-level validation must remain safe to execute multiple times as handlers are replaced/overwritten. For example, creating a `TaggedRule<>`, registering a handler, calling `validate()`, then registering a new handler and calling `validate()` again should succeed, and the rule should execute the latest registered handler.

The goal is that `validate()` becomes a reusable, side-effect-free validation step that can be invoked at any time during route setup to catch problems early, without requiring `run()` to surface these errors and without duplicating one-time setup work on repeated calls.