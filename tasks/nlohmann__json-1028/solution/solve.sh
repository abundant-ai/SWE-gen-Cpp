#!/bin/bash

set -euo pipefail
cd /app/src

patch -p1 < /solution/fix.patch

# Fix the _MSC_VER bug in the implicit conversion operator for string_view
# The condition should check if _MSC_VER is defined before comparing it
sed -i 's/#if defined(JSON_HAS_CPP_17) && _MSC_VER/#if defined(JSON_HAS_CPP_17) \&\& defined(_MSC_VER) \&\& _MSC_VER/g' single_include/nlohmann/json.hpp
sed -i 's/#if defined(JSON_HAS_CPP_17) && _MSC_VER/#if defined(JSON_HAS_CPP_17) \&\& defined(_MSC_VER) \&\& _MSC_VER/g' include/nlohmann/json.hpp
