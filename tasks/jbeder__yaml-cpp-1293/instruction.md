Floating-point values emitted by yaml-cpp are currently “uglified” because they are formatted via `std::stringstream` in a way that exposes binary floating-point artifacts. This makes round-tripping configuration files noisy and surprising. For example, emitting a mapping that contains doubles like `34.34` and `56.56` can produce strings like `34.340000000000003` and `56.560000000000002` instead of the expected human-friendly `34.34` and `56.56`.

The library should format floating-point scalars using the shortest decimal representation that round-trips back to the same floating-point value, avoiding the long tail of digits introduced by naive stream formatting. Add/implement a floating-point conversion API named `FpToString` (declared in `yaml-cpp/fptostring.h`) that converts floating-point values to strings using this “shortest round-trippable” formatting by default.

`FpToString` must satisfy these behaviors:

- Basic cases motivating the issue must produce clean output:
  - `FpToString(34.34)` returns `"34.34"`
  - `FpToString(56.56)` returns `"56.56"`
  - `FpToString(12.12)` returns `"12.12"`
  - `FpToString(78.78)` returns `"78.78"`

- It must handle large/sensitive float values without incorrect rounding. For the value `1.5474250491e+26f`:
  - Default formatting must return exactly `"1.54743e+26"`.
  - When called with an explicit precision of 8 significant digits, it must return exactly `"1.5474251e+26"`.

- For a broad set of “ordinary” values, output should match the conventional formatting users expect from `std::stringstream`-style formatting when no custom precision is requested (except that it must avoid the uglified long representations).

- Default formatting must avoid scientific notation for values below 1e6, but use scientific notation at and above 1e6 using the following exact formatting expectations:
  - `FpToString(1.)` -> `"1"`
  - `FpToString(1e5)` -> `"100000"`
  - `FpToString(1e6)` -> `"1e+06"`
  - `FpToString(1e7)` -> `"1e+07"`
  - `FpToString(1e8)` -> `"1e+08"`
  - `FpToString(1e9)` -> `"1e+09"`

Once `FpToString` exists and behaves as above, yaml-cpp’s emitting/serialization path for float/double scalars should use this conversion so that YAML output no longer contains the ugly long decimal expansions for common decimal inputs, while preserving correct round-trip behavior and honoring user-configured float/double precision controls in the emitter where applicable.