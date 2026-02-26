Error reporting from yaml-cpp when accessing missing keys is currently too generic to debug in real configurations. When a user subscripts into a YAML::Node with a key that doesn’t exist and then either continues subscripting or converts to a concrete type, the library throws exceptions like YAML::InvalidNode or YAML::BadSubscript with messages that do not identify which key caused the failure (e.g., messages like "invalid node; this may result from using a map iterator as a sequence iterator, or vice-versa").

Improve YAML::InvalidNode and YAML::BadSubscript exception messages so that, when the first invalid key used in an operator[] access is printable (e.g., a string key or an integer index), the exception message includes that key. The goal is that users can immediately see which missing/incorrect key triggered the error without needing a debugger.

Reproduction scenarios that should produce improved messages:

1) BadSubscript should include the key when operator[] is called on a scalar.
Example YAML:
first:
  second: 1
  third: 2

If code attempts further subscripting into a scalar node, e.g.:
YAML::Node doc = YAML::Load(yaml_text);
auto n = doc["first"]["second"]["fourth"];
then the thrown YAML::BadSubscript message should be:
operator[] call on a scalar (key: "fourth")

Similarly, for an integer index key:
auto n = doc["first"]["second"][37];
message should be:
operator[] call on a scalar (key: "37")

If the key is not printable (e.g., complex types), the message should remain the generic form without a key suffix:
operator[] call on a scalar

2) InvalidNode should include the first invalid key when converting a missing node via as<T>().
With the same YAML and a const node:
const YAML::Node doc = YAML::Load(yaml_text);
int x = doc["first"]["fourth"].as<int>();
then YAML::InvalidNode should have message:
invalid node; first invalid key: "fourth"

Similarly for an integer index:
int x = doc["first"][37].as<int>();
message should be:
invalid node; first invalid key: "37"

If the key is not printable (e.g., a vector<int> used as a key), the YAML::InvalidNode message should remain the existing generic guidance:
invalid node; this may result from using a map iterator as a sequence iterator, or vice-versa

These changes should affect the exception message content (the stored message string, e.g., the msg field used by the exception), without changing the exception types thrown or the semantics of operator[] / as<T>() beyond improved diagnostics.