Google Mock should support a parameterless form of setting expectations/stubs that means “match any arguments” without requiring users to spell out the number of wildcard matchers.

Currently, users must write expectations like:

```cpp
ON_CALL(mock, Method(_, _, _)).WillByDefault(...);
EXPECT_CALL(mock, AnotherMethod(_, _, _, _)).WillOnce(...);
```

The problem is that this forces the caller to explicitly specify the arity of the mocked method (and keep it in sync if the signature changes), even when they conceptually want to match any arguments.

Implement support for a parameterless macro form where the method name is provided without an argument list, and it behaves as if all parameters were matched with wildcards. The following should compile and behave equivalently to the forms above:

```cpp
ON_CALL(mock, Method).WillByDefault(...);
EXPECT_CALL(mock, AnotherMethod).WillOnce(...);
```

This parameterless syntax must only be available for non-overloaded mock methods. If a user attempts to use the parameterless form with an overloaded method name (i.e., multiple overloads exist in the mock), it must fail to compile with a clear compiler error due to ambiguity/unavailability of the parameterless form.

Expected behavior:
- `ON_CALL(mock, Method)` creates a stub/expectation that matches calls to `Method` with any argument values (all arguments are unconstrained).
- `EXPECT_CALL(mock, Method)` likewise matches any arguments and supports the usual chaining (e.g., `WillOnce`, `WillRepeatedly`, `Times`, etc.).
- For a mock method with N parameters, the parameterless form must be equivalent to specifying N instances of the wildcard matcher (`_`).
- The feature must not silently pick an overload: using the parameterless form on overloaded methods must be ill-formed (compile-time failure).

Actual behavior prior to this change:
- `ON_CALL(mock, Method)` / `EXPECT_CALL(mock, Method)` is not accepted as a valid expectation specification and users must provide an explicit matcher list.

Provide the necessary API/macro support so that existing matcher-based forms continue to work unchanged, while the new parameterless form works for non-overloaded methods and is rejected for overloaded ones.