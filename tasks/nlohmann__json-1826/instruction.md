`nlohmann::json` is incorrectly considered constructible from certain `std::tuple` types due to the tuple-related `to_json` specialization being too permissive. In particular, `std::is_constructible<nlohmann::json, std::tuple<std::string, Data>>::value` currently evaluates to `true` even when `Data` is not serializable to JSON, which causes compile-time checks (e.g., `static_assert`) to fail.

Reproduction:
```cpp
#include <string>
#include <tuple>
#include <nlohmann/json.hpp>

struct Data {
    int mydata;
    float myfloat;
};

int main() {
    using nlohmann::json;
    static_assert(!std::is_constructible<json, std::tuple<std::string, Data>>::value, "");
}
```

Current behavior: the `static_assert` fails because `std::is_constructible<json, std::tuple<std::string, Data>>::value` is `true`.

Expected behavior: `std::is_constructible<json, std::tuple<std::string, Data>>::value` must be `false` unless every element of the tuple can be converted to JSON (i.e., the library should not advertise tuple-to-JSON conversion/constructor availability when any tuple element lacks a valid `to_json` conversion).

Implement a stricter restriction on the tuple-related `to_json`/construction machinery so that constructibility and overload resolution properly SFINAE-out for tuples containing non-serializable element types, while continuing to allow tuples whose elements are all JSON-convertible.