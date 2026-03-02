When using Crow as a header-included dependency in a normal C++ project with multiple .cpp files, the project can fail at link time with a multiple-definition error for a Crow symbol.

A typical failure looks like:

```
/usr/bin/ld: ... multiple definition of `crow::method_strings'; ... first defined here
collect2: error: ld returned 1 exit status
```

This happens when more than one compilation unit includes Crow headers and the resulting object files are linked together. The symbol involved is `crow::method_strings` (an array of HTTP method names). Because of how it is currently defined, including the relevant header in multiple translation units produces multiple strong definitions, violating the One Definition Rule and causing the linker to error.

The library must be changed so that including Crow headers from multiple translation units does not emit multiple definitions of `crow::method_strings`. The symbol should either not be a multiply-defined global, or otherwise be defined in a way that is safe across translation units.

Reproduction scenario: create a small executable with at least two source files; in each source file include Crow (e.g., `#include <crow.h>`). In one of the files, instantiate and use `crow::SimpleApp` (for example, define a `CROW_ROUTE` and call `app.port(...).run();`). Building and linking this executable should succeed without any multiple-definition linker errors.

Expected behavior: A multi-file project that includes Crow headers in multiple .cpp files links successfully.

Actual behavior: The linker fails with a multiple definition of `crow::method_strings`.