The library currently requires the number and types of formatting arguments to be known at compile time (e.g., via variadic formatting calls). This blocks use cases where a format string is loaded dynamically (e.g., from a config file) and arguments are assembled at runtime from a dictionary or other data source.

Implement an API that allows fully dynamic construction of a formatting argument list and then formatting with it. The API should provide a type named `fmt::dynamic_format_arg_store<Context>` (for example with `Context = fmt::format_context`) that can store an ordered list of arguments added at runtime via `push_back(...)`. Once populated, the store must be usable directly with `fmt::vformat(format_string, store)` to produce the same output as if the arguments had been passed statically.

Required behavior:

- Basic dynamic positional arguments: After doing
  ```cpp
  fmt::dynamic_format_arg_store<fmt::format_context> store;
  store.push_back(42);
  store.push_back("abc1");
  store.push_back(1.5f);
  auto s = fmt::vformat("{} and {} and {}", store);
  ```
  the result must be exactly `"42 and abc1 and 1.5"`.

- String lifetime/ownership semantics must be correct for different string-like inputs:
  - If a mutable character buffer is passed (e.g., `char str[] = "123..."; store.push_back(str);`) and then the buffer is modified after `push_back`, formatting must still use the original content captured at `push_back` time (i.e., `push_back(char*)` should not keep a non-owning pointer that later reflects mutations).
  - If a reference wrapper is passed (e.g., `store.push_back(std::cref(str));`) then formatting must reflect the current value at formatting time (mutations after `push_back` must be visible).
  - If a `fmt::string_view` is passed, it is allowed to be non-owning; formatting should reflect the view contents at formatting time.
  Concretely, with:
  ```cpp
  fmt::dynamic_format_arg_store<fmt::format_context> store;
  char str[]{"1234567890"};
  store.push_back(str);
  store.push_back(std::cref(str));
  store.push_back(fmt::string_view{str});
  str[0] = 'X';
  auto s = fmt::vformat("{} and {} and {}", store);
  ```
  the result must be exactly `"1234567890 and X234567890 and X234567890"`.

- Custom type formatting must work and must preserve value/reference semantics:
  If a user provides a `fmt::formatter<custom_type>` specialization, pushing values should capture the value at the time of `push_back`, while pushing `std::cref(obj)` should format using the object’s current state at formatting time. For example, if `custom_type` has an integer field `i` and formats as `cust=<i>`, then after:
  ```cpp
  fmt::dynamic_format_arg_store<fmt::format_context> store;
  custom_type c{};
  store.push_back(c);      // should format as cust=0
  ++c.i;
  store.push_back(c);      // should format as cust=1
  ++c.i;
  store.push_back(std::cref(c)); // reference; subsequent mutation should be seen
  ++c.i;
  auto s = fmt::vformat("{} and {} and {}", store);
  ```
  the result must be exactly `"cust=0 and cust=1 and cust=3"`.

- Named arguments must be supported, including by-reference named arguments:
  `fmt::arg(name, value)` produces a named-argument object that refers to its value. The dynamic store must be able to accept a reference to such a named-argument object (e.g., `store.push_back(std::cref(a1));`) and allow formatting by name:
  ```cpp
  fmt::dynamic_format_arg_store<fmt::format_context> store;
  int a1_val = 42;
  auto a1 = fmt::arg("a1_", a1_val);
  store.push_back(std::cref(a1));
  auto s = fmt::vformat("{a1_}", store);
  ```
  The result must be exactly `"42"`.

Overall, the dynamic argument store must interoperate with the existing formatting API such that users can build argument lists at runtime (including heterogeneous types and named args) and pass them to `fmt::vformat` without needing compile-time knowledge of the number/types of arguments.