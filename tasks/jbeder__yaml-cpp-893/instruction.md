Building yaml-cpp with Clang fails due to missing standard library includes and incorrect use of a C++ standard algorithm in the library code. In addition, some range-based for loops use an identifier named `it`, which is not a valid iterator variable name in that context and can lead to compilation errors or warnings treated as errors under Clang.

The library should compile cleanly under Clang (including common configurations that treat warnings as errors) without requiring downstream projects to add extra headers or special compiler flags. After the fix, code that uses the public API should continue to work as before; for example:

```cpp
YAML::Node node = YAML::Load("foo");
node = YAML::Node();
bool isNull = node.IsNull();

YAML::Node m = YAML::Load("foo: bar\nx: 2");
std::string v = m["foo"].as<std::string>();
std::string fallback = m["baz"].as<std::string>("hello");
int x = m["x"].as<int>();
int y = m["y"].as<int>(5);
```

Expected behavior: the project compiles successfully with Clang, and the above API interactions behave normally (e.g., reassigned nodes become null, `as<T>(fallback)` returns the fallback when the key is missing, and numeric conversions/typed conversion errors remain consistent).

Actual behavior: compilation fails under Clang with errors consistent with missing declarations from standard headers and misuse of a standard algorithm (e.g., template/overload resolution failures), preventing the library and dependent code from building.