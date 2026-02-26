Using compile-time format strings via FMT_STRING (and the "..."_format literal) currently rejects named arguments unless they are passed as runtime-named arguments created with fmt::arg("name", value). This produces a compile-time failure with a static assertion like:

static assertion failed: use statically named arguments with compile-time format strings: fmt::arg("name", value) -> "name"_a = value

The library should support statically named arguments with compile-time format strings when the compiler supports non-type template arguments for the name. For example, the following should compile and format correctly (order of arguments should not matter):

fmt::format(FMT_STRING("{foo}{bar}"), "bar"_a = "bar", "foo"_a = "foo");
"{foo}{bar}"_format("bar"_a = "bar", "foo"_a = "foo");

Expected behavior: compile-time format strings accept statically named arguments created with the "name"_a syntax, and formatting resolves the names correctly regardless of the order they are provided.

Actual behavior: compile-time format strings do not accept these statically named arguments and/or fail name resolution at compile time, forcing users toward runtime-named arguments or triggering the static assertion.

Implement support so that compile-time checking for named arguments recognizes statically named arguments ("name"_a = value) as valid for compile-time format strings and matches them against placeholders like {foo} and {bar} during compile-time parsing/validation.