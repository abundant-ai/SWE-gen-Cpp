#!/bin/bash

cd /app/src

# This PR adds special treatment for writing single quotes within attribute values
# The fix escapes single quotes as &apos; in attribute values

# Create a simple test program to check if single quotes are escaped in attributes
cat > /tmp/test_single_quote.cpp << 'EOF'
#include "src/pugixml.hpp"
#include <iostream>
#include <sstream>

int main() {
    pugi::xml_document doc;
    pugi::xml_node node = doc.append_child("node");

    // Set an attribute value that contains a single quote
    node.append_attribute("attr") = "<>'\"";

    // Write to string
    std::ostringstream oss;
    doc.save(oss, "", pugi::format_raw | pugi::format_no_declaration);
    std::string output = oss.str();

    // Check if single quote is escaped as &apos;
    if (output.find("&apos;") != std::string::npos) {
        std::cout << "PASS: Single quotes are escaped as &apos;" << std::endl;
        return 0;
    } else if (output.find("attr=\"<>'\"") != std::string::npos) {
        std::cout << "FAIL: Single quotes are NOT escaped (found raw ')" << std::endl;
        return 1;
    } else {
        std::cout << "UNEXPECTED: Output was: " << output << std::endl;
        return 1;
    }
}
EOF

# Compile the test program
g++ -std=c++11 -I. /tmp/test_single_quote.cpp src/pugixml.cpp -o /tmp/test_single_quote

# Run the test
/tmp/test_single_quote
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
