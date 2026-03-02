#include <nlohmann/json.hpp>

// This function is never called but forces instantiation of ordered_map::at()
// which will fail to compile with -fno-exceptions if using raw throw
void force_instantiation() {
    nlohmann::ordered_map<std::string, nlohmann::json> m;
    m["key"] = 1;
    // Reference the at() method to force its instantiation
    volatile auto& ref = m.at("key");
    (void)ref;
}

int main(int argc, char **argv)
{
    nlohmann::json j;
    return 0;
}
