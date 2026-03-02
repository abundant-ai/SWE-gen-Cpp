Crow currently supports middleware at the application and per-route level, but middleware cannot be attached to a Blueprint in a way that composes correctly through nested blueprints. As a result, when a route is registered under a Blueprint (or a Blueprint registered under another Blueprint), middleware that conceptually belongs to the blueprint hierarchy is either not invoked at all, invoked in the wrong order, or cannot be expressed with the public API.

Add support for blueprint middleware such that middleware can be declared on a Blueprint and will be executed for every request handled by routes within that blueprint, including when blueprints are nested. Middleware attached closer to the application root should run before middleware attached deeper in the blueprint tree, and per-route middleware should run last.

The API must support the following usage patterns:

- Declaring middleware on a blueprint by listing middleware types, e.g.
  - `crow::Blueprint<Mw1, Mw2> bp;` (or equivalent blueprint construction that associates Mw1/Mw2 with the blueprint)
  - and/or `bp.CROW_MIDDLEWARES(app, Mw1, Mw2);` to bind a blueprint’s middleware to the middleware types available in the target `crow::App<...>` instance.

- Declaring middleware on a specific route created from a blueprint rule, e.g.
  - `CROW_BP_ROUTE(bp, "/").CROW_MIDDLEWARES(app, ThirdMW)(handler);`

Blueprint middleware must compose transitively through nested registration. For example, given:

```c++
crow::App<FirstMW, SecondMW, ThirdMW> app;

crow::Blueprint bp1("a", "c1", "c1");
bp1.CROW_MIDDLEWARES(app, FirstMW);

crow::Blueprint bp2("b", "c2", "c2");
bp2.CROW_MIDDLEWARES(app, SecondMW);

CROW_BP_ROUTE(bp2, "/")
    .CROW_MIDDLEWARES(app, ThirdMW)
    ([](const crow::request& req) {
        return "";
    });

bp1.register_blueprint(bp2);
app.register_blueprint(bp1);
```

A request to the registered endpoint must execute middleware in this order: `FirstMW` (from `bp1`), then `SecondMW` (from `bp2`), then `ThirdMW` (from the route), then finally the handler.

Constraints/requirements:

- The middleware types referenced by a blueprint or route must be present in the app’s middleware list (`crow::App<...>`). If a user attempts to attach a middleware type that is not part of the app, it must fail clearly (preferably at compile time with a meaningful message).

- Blueprint middleware must not require users to manually “flatten” middleware types through templates when nesting blueprints; nested blueprints should remain usable with homogeneous storage and registration.

- Existing behavior for applications without blueprints, and for route-level middleware, must remain intact.

- Middleware execution must still follow Crow’s established `before_handle` / `after_handle` semantics (where applicable) with correct ordering relative to nesting.

After implementing, validation/registration and request handling should work correctly when:

1) Middleware is attached only at the app level.
2) Middleware is attached at blueprint level (single blueprint).
3) Middleware is attached across multiple nested blueprints.
4) Middleware is attached both at blueprint level and per-route level, and the full chain executes in the expected order.

If middleware cannot be invoked due to missing association between blueprint-declared middleware and the app’s middleware container, registration should fail rather than silently ignoring middleware.