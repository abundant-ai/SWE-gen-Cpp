Parsing certain malicious or deeply nested YAML inputs can trigger unbounded recursion and crash the process with a stack overflow (e.g., SIGSEGV/ASAN stack-overflow). This affects parsing of deeply nested flow sequences and flow maps and can be reproduced by feeding a YAML stream consisting of many repeated opening flow delimiters.

Reproduction examples:
- If the input is a string containing 16,384 consecutive '[' characters (with no corresponding closing brackets), then creating a YAML::Parser on that stream and calling Parser::HandleNextDocument(...) currently leads to runaway recursion in the document parser and can overflow the stack.
- If the input is a string containing tens of thousands of consecutive '{' characters (e.g., 20,535; 21,989) and then parsing the next document, the parser can similarly recurse until stack exhaustion.
- If the input is 23,100 consecutive '[' followed by a scalar character like 'f', parsing the next document can still overflow the stack.

Instead of crashing, Parser::HandleNextDocument(YAML::EventHandler&) must detect excessive recursion depth during parsing and abort parsing by throwing YAML::DeepRecursion.

The recursion limit must be enforced in the code paths that recursively process nodes, including flow sequences and flow maps (e.g., SingleDocParser::HandleNode(...), SingleDocParser::HandleFlowSequence(...), SingleDocParser::HandleFlowMap(...)), and also in scanning/tokenization paths that can recurse or loop in a way that grows the call stack (e.g., Scanner::EnsureTokensInQueue()).

Expected behavior:
- For sufficiently deep or adversarial nesting (including the inputs described above), Parser::HandleNextDocument(...) throws YAML::DeepRecursion reliably and does not segfault or trigger ASAN stack-overflow.
- For normal YAML inputs, parsing behavior remains unchanged (no DeepRecursion thrown under typical nesting depths).