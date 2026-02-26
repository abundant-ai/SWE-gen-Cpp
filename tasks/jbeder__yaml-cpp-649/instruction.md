yaml-cpp currently loses correctness when emitting floating-point scalars (float/double) to YAML and then parsing them back, because the emitted textual representation does not preserve enough precision for a reliable round trip.

Reproduction examples:

1) Round-trip mismatch due to insufficient precision

```cpp
YAML::Node n;
double x = 1.0 + std::numeric_limits<double>::epsilon();
n["x"] = x;
std::stringstream ss;
ss << n;                 // serialize
YAML::Node m = YAML::Load(ss.str());
double y = m["x"].as<double>();
```

Expected behavior: `y` must equal `x` exactly (same IEEE-754 value) for typical finite values when a node is serialized and read back.

Actual behavior: `y` can differ from `x` because the string form is truncated (commonly due to using `std::numeric_limits<T>::digits10`-level precision), so parsing produces a neighboring representable value.

2) Reading maximum double can fail after writing it

```cpp
YAML::Node w;
w["double"] = std::numeric_limits<double>::max();
std::stringstream ss;
ss << w;
YAML::Node r = YAML::Load(ss.str());
double d = r["double"].as<double>();
```

Expected behavior: converting the scalar back via `Node::as<double>()` succeeds and returns `std::numeric_limits<double>::max()`.

Actual behavior: the conversion can throw a `bad conversion` error when attempting `as<double>()` for the max double value.

3) Float precision regression example

Serializing a float like `0.12345679f` and reading it back can produce a different float (e.g., serialized as `0.12345678`), meaning the round trip changes the stored value.

The library should emit floats/doubles with sufficient precision so that parsing the emitted scalar yields the same original floating-point value (round-trip guarantee) for finite values. This should apply consistently whether the value is emitted via `YAML::Emitter` or streamed out from a `YAML::Node`, and the result must be parseable by `YAML::Load(...)` / `YAML::LoadFile(...)` and convertible via `Node::as<float>()` and `Node::as<double>()` without throwing for representable values such as `numeric_limits<double>::max()`.

Additionally, unit-level expectations that compare emitted YAML strings should not rely on unstable decimal renderings of non-exactly representable floats; emitted representations must be stable and correct for values that can be represented exactly, and floating-point round-tripping must be validated by comparing the recovered numeric value with the original.