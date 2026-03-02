The server routing API currently requires users to write regexes for dynamic path segments and to rely on capture-group ordering to retrieve values, which is error-prone when the same parameter appears in multiple routes (e.g., "/projects/11" and "/projects/11/files"). Add support for registering routes using named path parameters in the path string itself, using a simple parameter syntax like ":id" (and/or an equivalent familiar form), so that users do not need to supply explicit regex patterns for common path parameters.

A new set of routing registration methods must be available on the server with a distinct name from the existing regex-based ones (e.g., methods suffixed with "Simple" such as GetSimple/PostSimple/PutSimple/PatchSimple/DeleteSimple/OptionsSimple). When a request matches one of these routes, the server must parse the path and populate a map of path parameters on the Request object, exposed as Request::path_params, keyed by parameter name.

Example expected usage:

```cpp
svr.GetSimple("/users/:id", [&](const Request &req, Response &) {
  // Path parameters must be retrievable by name
  auto id = req.path_params.at("id");
});
```

For a request like GET /users/user-id?param1=foo&param2=bar, the handler must observe:
- req.path_params.at("id") == "user-id"
- Existing query string parsing must continue to work, e.g. req.get_param_value("param1") returns "foo" and req.get_param_value("param2") returns "bar".

Route matching rules should ensure that named parameters match a single path segment (i.e., they should not consume '/' characters), so that "/projects/:id" does not unintentionally match "/projects/11/files" unless a corresponding route pattern explicitly includes that additional segment.

If a route contains multiple named parameters (e.g., "/orgs/:org/users/:id"), all must be captured into Request::path_params under their respective keys. If a parameter key is not present, Request::path_params.at(key) should behave like a standard map access (i.e., throw) rather than silently returning an empty string.