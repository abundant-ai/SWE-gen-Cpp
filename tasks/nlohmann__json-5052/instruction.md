In C++17+ builds, returning a `nlohmann::json` value from a function whose return type is `std::optional<nlohmann::json>` can fail to compile due to an ambiguous conversion.

For example, the following code should compile (it compiled in v3.12.0), but on current `develop` it fails with an error like:

`conversion from 'const nlohmann::basic_json<>' to 'std::optional<json>' is ambiguous`

```cpp
#include <nlohmann/json.hpp>
#include <optional>

using json = nlohmann::json;
inline constexpr const char* CFG_PROP_DEFAULT = "default";

std::optional<json> GetValue(const json& valRoot)
{
    if (valRoot.contains(CFG_PROP_DEFAULT)) {
        return valRoot.at(CFG_PROP_DEFAULT);
    }
    return std::nullopt;
}
```

Expected behavior: When a `nlohmann::json` value (including a `const json&` returned by `json::at(...)`) is returned from a function returning `std::optional<json>`, the compiler should be able to form an `std::optional<json>` without ambiguity, preserving the implicit-conversion behavior that worked in v3.12.0.

Actual behavior: With C++20 (observed with MSVC and clang-cl on Windows), the return statement `return valRoot.at(...);` fails to compile because `std::optional<json>` construction from `json` becomes ambiguous.

Fix the library so that `std::optional<nlohmann::json>` can be constructed unambiguously from a `nlohmann::json` value/reference in this return context, restoring source compatibility for code that returns `json` where `std::optional<json>` is expected.