Parsing certain maliciously-crafted YAML inputs can crash the process with a stack overflow due to unbounded recursion in the parser. This is reproducible by feeding the command-line parser utility with inputs consisting of extremely deep/nested flow collections (e.g., thousands of consecutive '[' or '{' characters), which causes repeated recursive calls in parsing routines such as YAML::SingleDocParser::HandleNode(), YAML::SingleDocParser::HandleFlowSequence(), and YAML::SingleDocParser::HandleFlowMap(), eventually triggering an AddressSanitizer stack-overflow or a SIGSEGV.

The parser must detect excessive recursion depth and fail safely by throwing YAML::DeepRecursion (from <yaml-cpp/exceptions.h>) instead of recursing until the program crashes. This should be enforced when a user calls Parser::HandleNextDocument(YAML::EventHandler&).

Concretely, the following scenarios must no longer crash and must throw YAML::DeepRecursion:

- When the input is a string composed of 16,384 consecutive '[' characters, calling Parser parser{input_stream}; then parser.HandleNextDocument(handler) must throw YAML::DeepRecursion.
- When the input is a string composed of 20,535 consecutive '{' characters, Parser::HandleNextDocument must throw YAML::DeepRecursion.
- When the input is a string composed of 21,989 consecutive '{' characters, Parser::HandleNextDocument must throw YAML::DeepRecursion.
- When the input is a string composed of 23,100 consecutive '[' characters followed by a single 'f' character, Parser::HandleNextDocument must throw YAML::DeepRecursion.

The fix must ensure recursion depth is tracked/guarded across the relevant parsing steps so that deeply nested flow sequences/maps (and related node handling) are covered, preventing stack overflows in the reported call chains (e.g., HandleNode ↔ HandleSequence/HandleMap ↔ HandleFlowSequence/HandleFlowMap and similar loops).