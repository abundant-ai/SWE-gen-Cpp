When accessing YAML nodes with operator[] and then converting via .as<T>(), the library throws exceptions like YAML::InvalidNode or YAML::BadSubscript with messages that are too generic to debug. In particular, when a map lookup fails due to a missing key (often caused by typos), the thrown YAML::InvalidNode currently reports a generic message like:

"invalid node; this may result from using a map iterator as a sequence iterator, or vice-versa"

This message does not reveal which key lookup failed, making it difficult to diagnose configuration issues without a debugger.

Update error reporting so that YAML::InvalidNode and YAML::BadSubscript include the first invalid key/index in the exception message when that key is printable (e.g., string keys and numeric indices). The message should still fall back to the existing generic wording when the key is not printable (for example, complex types used as a key).

Concrete expected behavior:

1) BadSubscript message should include the printable key/index when operator[] is invoked on a scalar.
Example YAML:
first:
  second: 1
  third: 2

- Evaluating doc["first"]["second"]["fourth"] should throw YAML::BadSubscript with message:
  operator[] call on a scalar (key: "fourth")

- Evaluating doc["first"]["second"][37] should throw YAML::BadSubscript with message:
  operator[] call on a scalar (key: "37")

- If the key is not printable (e.g., a complex object or an empty/unspecified key), the message should remain:
  operator[] call on a scalar

2) InvalidNode message should include the first invalid key/index when a lookup fails and then .as<T>() is called.
Using the same YAML as above:

- Evaluating doc["first"]["fourth"].as<int>() should throw YAML::InvalidNode with message:
  invalid node; first invalid key: "fourth"

- Evaluating doc["first"][37].as<int>() should throw YAML::InvalidNode with message:
  invalid node; first invalid key: "37"

- If the key is not printable, YAML::InvalidNode should keep the existing generic message:
  invalid node; this may result from using a map iterator as a sequence iterator, or vice-versa

The goal is that common configuration mistakes (like misspelled keys) surface the failing key directly in the exception string, without changing the behavior for non-printable keys.