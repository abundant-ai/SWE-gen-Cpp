fmt::dynamic_format_arg_store<Context> cannot currently be copied, which prevents creating a new argument scope based on an existing store (e.g., copying a base set of arguments and then appending additional ones) without mutating the original. Attempting to do something like:

```c++
fmt::dynamic_format_arg_store<fmt::format_context> args;
args.push_back(42);
args.push_back(fmt::arg("name", "Alice"));

fmt::dynamic_format_arg_store<fmt::format_context> args2(args); // should compile
args2.push_back(fmt::arg("extra", "value"));
```

fails because the type is not copy-constructible.

Add proper default construction and a copy constructor for fmt::dynamic_format_arg_store<Context> so that:

- Copying a store produces a logically equivalent store that can be used with fmt::vformat in the same way as the original.
- After copying, the original store must remain unchanged when the copy is appended to (e.g., args2.push_back(...) must not affect args).
- The copy must preserve positional and named arguments such that formatting with either automatic fields ("{}") or named fields ("{name}") works the same as with the source store.
- The copy must preserve the existing value-vs-reference behavior of stored arguments (e.g., storing a C string by value vs storing a reference wrapper should continue to behave consistently after copying when the original underlying object is later mutated).

The result should allow using a copied store as a base and then adding more arguments, with fmt::vformat producing expected output for both positional and named formatting using the copied store.