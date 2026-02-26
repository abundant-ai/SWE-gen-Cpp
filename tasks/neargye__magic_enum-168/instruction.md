A new “enum switch” facility is expected to work with magic_enum so that users can dispatch on an enum value without manually writing a switch statement, while still supporting the same enum types and customization rules as the rest of the library.

Currently, attempting to use the enum-switch API with enums that have non-contiguous values, negative values, custom enum ranges, or a boolean underlying type either fails to compile or produces incorrect dispatch (the wrong case is executed or the default path is taken) compared to what magic_enum reports as valid values.

Implement or fix the enum-switch functionality so that:

- Dispatch works correctly for scoped and unscoped enums whose enumerators are sparse and can include negative values (e.g., values like -120, -42, 85, 120).
- Dispatch honors magic_enum customization points, especially magic_enum::customize::enum_range<E>::min/max, so only values in the customized range participate in dispatch and lookups.
- Dispatch remains correct when an enum uses a sentinel value outside the configured range (e.g., an INVALID enumerator equal to std::numeric_limits<underlying_type>::max()), ensuring that sentinel values do not get treated as valid in-range enumerators.
- Enums with underlying type bool are handled correctly (no ambiguous overloads, no incorrect indexing/bitset assumptions, and correct mapping of the two possible values).
- The feature is compatible with custom magic_enum::customize::enum_name<E>(E) and still produces consistent behavior with name/value discovery (i.e., values that magic_enum considers valid should be dispatchable; values considered invalid should go to the default path).

The API should provide a way to associate handlers with specific enum enumerators and execute the matching handler when called with a runtime enum value, falling back to a default handler when the value is not a valid enumerator (or is out of the customized range). Compilation should succeed across the supported compilers and standard modes used by the project.