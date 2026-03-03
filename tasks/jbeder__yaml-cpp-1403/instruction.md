`YAML::LoadAll()` fails to parse YAML streams that contain empty documents in yaml-cpp 0.9.0.

In yaml-cpp 0.8.0, calling `YAML::LoadAll()` on a stream containing document separators with no content between them correctly returns entries for those empty documents. In yaml-cpp 0.9.0, the same input incorrectly returns an empty result (size 0), indicating the parser stops early or skips documents entirely.

Reproduction:

```c++
#include <iostream>
#include <yaml-cpp/yaml.h>

int main() {
  const char* const docs = R"(
---
---
A
)";

  const auto parsed = YAML::LoadAll(docs);
  std::cout << parsed.size() << "\n";
}
```

Expected behavior:
- `YAML::LoadAll(docs)` should return 2 documents for the example above: the first document is empty (should be represented as a null/empty `YAML::Node`), and the second document contains the scalar `"A"`.
- Therefore `parsed.size()` should print `2`.

Actual behavior in 0.9.0:
- `YAML::LoadAll(docs)` returns an empty vector and `parsed.size()` prints `0`.

Fix required:
- Restore correct handling of empty documents in a multi-document stream when using `YAML::LoadAll()`.
- Ensure that document separators (`---`) with no following content still produce a corresponding `Node` in the returned list rather than being dropped or causing parsing to terminate.
- The behavior should be consistent across combinations like leading empty documents, consecutive empty documents, and empty documents followed by a non-empty document (e.g., `---\n---\nA\n`).