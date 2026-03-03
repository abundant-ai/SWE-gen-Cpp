Some JSON producers (notably crypto exchanges) encode numeric values inside JSON strings, e.g. {"price":"443.7807865468","timestampstr":"1399490941"}. In simdjson ondemand, callers can currently decode numeric tokens via get_double(), get_int64(), and get_uint64(), but these fail or return a type error when the value is a JSON string even if the string contents are a valid JSON number.

Add support in ondemand for parsing numbers that are enclosed in quotes, without requiring the user to first extract the string and run a separate conversion routine.

The API should provide the following methods on ondemand values (and work when iterating arrays and objects):

- value.get_double_in_string() should parse a JSON string whose contents represent a floating-point number (including optional sign and exponent, e.g. "2.43442e3" and "-1.234e3") and return it as a double.
- value.get_int64_in_string() should parse a JSON string whose contents represent a signed integer (e.g. "-7844") and return it as int64_t.
- value.get_uint64_in_string() should parse a JSON string whose contents represent an unsigned integer (e.g. "156934") and return it as uint64_t.

These methods should succeed for arrays like ["1.2","2.3","-42.3","2.43442e3","-1.234e3"] and ["1","2","-3","1000","-7844"], and for objects with numeric strings as values.

When the value is not a string, these “_in_string” methods should return the appropriate type error rather than silently accepting other JSON types.

When the string contents are not a valid number for the requested type (for example "Infinity" for double, non-numeric text, or values out of range for the target integer type), the methods should return a parse/number error consistent with existing ondemand numeric parsing errors.

The behavior should not loosen JSON parsing generally: quoted numbers should only be accepted by these explicit “_in_string” accessors, not by the regular get_double()/get_int64()/get_uint64() accessors.