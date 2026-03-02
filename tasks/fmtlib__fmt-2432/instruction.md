Currently, fmt::dynamic_format_arg_store<Context> cannot be copied because it lacks a copy constructor (and in some configurations is also missing a usable default constructor). This prevents common workflows where a “base” argument store is prepared and then extended in a derived scope without mutating the original store.

Implement proper construction support for fmt::dynamic_format_arg_store<Context> so that the following usage works as expected:

```cpp
fmt::dynamic_format_arg_store<fmt::format_context> args;
args.push_back(fmt::arg("global_username", std::ref("utkarsh1")));
args.push_back(fmt::arg("global_hostname", std::ref("miron")));
std::vector<int> v1 = {5, 1235, 1235123};
args.push_back(fmt::arg("global_vector", v1));

fmt::dynamic_format_arg_store<fmt::format_context> args2(args);
args2.push_back(fmt::arg("extra", std::ref("extra-value")));

auto s1 = fmt::vformat("{global_username} {global_hostname}", args);
auto s2 = fmt::vformat("{global_username} {global_hostname} {extra}", args2);
```

Expected behavior:
- args2 constructed from args contains the same positional and named arguments as args at the time of copying.
- After copying, pushing additional arguments into args2 must not affect args.
- Formatting with fmt::vformat using args and args2 should resolve the correct values for both positional and named placeholders.
- The copy must preserve correct behavior for a variety of stored argument kinds, including:
  - integers/floats
  - C strings and string views
  - values stored by value vs by reference (e.g., std::cref)
  - custom formattable types

Actual behavior (before the fix):
- Copy construction is not available, so code like `fmt::dynamic_format_arg_store<fmt::format_context> args2(args);` fails to compile.

Add the necessary constructors/semantics so dynamic_format_arg_store is default-constructible and copy-constructible, and ensure copied stores continue to work with fmt::vformat for both positional and named arguments.