When yaml-cpp emits floating-point scalars, it currently relies on std::stringstream-style formatting, which can produce “uglified” decimal strings that expose binary floating-point artifacts. For example, values like 34.34 may be emitted as "34.340000000000003" (and similarly 56.56 -> "56.560000000000002"), causing YAML configs to become noisy and unstable when read-modified-written.

The library needs a dedicated floating-point to string conversion routine that produces a short, human-friendly representation while still guaranteeing round-trip safety (parsing the emitted string yields the same floating-point value). Add a public function named `YAML::FpToString` that converts floating-point values to strings using shortest-representation logic with round-trip guarantee, and integrate it into the emitter so that floating-point scalars no longer get the long artifact-filled expansions by default.

Required behavior for `YAML::FpToString`:
- `YAML::FpToString(34.34)` must return exactly "34.34" (same for 56.56, 12.12, 78.78).
- It must handle values that are sensitive to rounding and still produce a correct short representation; for example `YAML::FpToString(1.5474250491e+26f)` must produce "1.54743e+26".
- `YAML::FpToString(value, precision)` must respect an explicit precision argument when provided; for example `YAML::FpToString(1.5474250491e+26f, 8)` must return "1.5474251e+26".
- Default formatting should match common stream output expectations for general cases, including:
  - Integers represented as floating point should not have trailing ".0" by default (e.g., `YAML::FpToString(1.0)` returns "1").
  - Values below 1e6 should be printed without scientific notation by default (e.g., 1e5 -> "100000").
  - Values at or above 1e6 should use scientific notation in the form used by the emitter (e.g., 1e6 -> "1e+06", 1e7 -> "1e+07").

Emitter integration requirements:
- When emitting YAML, floating-point values should use the new conversion so that common decimal inputs (like 34.34) are emitted cleanly and are stable across read/modify/write cycles.
- Existing emitter controls for float/double precision (e.g., setting float precision and double precision) must continue to work and must affect emitted output consistently with the above precision behavior.

If the implementation is incomplete, users will continue to see output like:

```yaml
latitude: 34.340000000000003
longitude: 56.560000000000002
```

instead of the expected:

```yaml
latitude: 34.34
longitude: 56.56
```

Implement the new conversion function and ensure YAML emission uses it so that emitted floating-point scalars are “pretty” and round-trip safe, while preserving existing precision and scientific-notation conventions.