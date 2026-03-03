Floating-point scalars written by yaml-cpp do not reliably round-trip through YAML text back into the same in-memory float/double value. This shows up in several ways:

When a float/double is serialized (for example by inserting it into a YAML::Node and emitting it, or by streaming a node/emitter to an output stream) and then later parsed back (for example via YAML::Load/YAML::LoadFile and converted using node.as<float>() / node.as<double>()), the parsed numeric value can differ from the original, even when the scalar is intended to represent the same value. A common reproduction is writing a value like 1 + epsilon, or values near float precision boundaries such as 0.12345679f, which can serialize to a decimal string that parses back to a neighboring representable value.

Additionally, certain large values that should be representable fail to parse back at all. In particular, serializing numeric_limits<double>::max() and then reading it back can cause node.as<double>() to throw a conversion error (commonly surfaced as a “bad conversion” when converting the scalar to double), while the analogous max float round-trips successfully.

The library should ensure that emitted YAML for float and double uses enough significant digits so that a parse of the emitted scalar yields the exact same floating-point value that was originally serialized (round-trip guarantee). This applies at least to the following flows:

- Writing a float/double into a YAML::Node (e.g., node["x"] = some_double) and emitting it, then reading it back and calling node["x"].as<float>() / as<double>().
- Emitting floating-point values via YAML::Emitter so that the resulting YAML scalar can be parsed back with no value change.

Expected behavior:
- For float: serializing a value like 0.12345679f and reading it back should produce a float that is bitwise-identical (or at minimum within < 1 ULP) to the original value; it must not deterministically round to a different adjacent float.
- For double: serializing numeric_limits<double>::max() and reading it back should not throw; node.as<double>() should succeed and return the original value.
- In general: float/double scalars should be emitted with sufficient precision such that YAML::Load(...)[key].as<T>() returns the same T value that was originally emitted.

Actual behavior:
- Emitted float/double strings can be too short (insufficient precision), causing the parsed value to differ from the original.
- Extremely large doubles (e.g., numeric_limits<double>::max()) may emit in a form that cannot be converted back by node.as<double>(), resulting in a thrown conversion/representation error.

Fix the float/double emission and conversion behavior so that round-tripping through YAML text preserves values and does not throw for valid finite values at the extremes of representable ranges.