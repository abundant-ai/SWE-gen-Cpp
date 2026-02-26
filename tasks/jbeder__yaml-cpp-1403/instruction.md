`YAML::LoadAll()` incorrectly handles YAML streams that contain empty documents (documents that consist of only a document start marker `---` and no content). This is a regression: in version 0.8.0, loading a stream with multiple empty documents returns the correct number of documents, but in 0.9.0 the same input returns an empty result.

Reproduction:

```cpp
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

Expected behavior: `YAML::LoadAll(docs)` should return a sequence-like container with one entry per YAML document in the stream. For the example above, it should return 2 documents (the first is an empty document, the second contains the scalar `A`).

Actual behavior: On 0.9.0, `YAML::LoadAll(docs)` returns 0 documents for this input.

The fix should ensure that `YAML::LoadAll()` correctly counts and returns empty documents when they are explicitly present in the stream (e.g., introduced by `---`), without breaking normal parsing of non-empty documents. Empty documents should be represented as a valid `YAML::Node` (typically a null/empty node), and mixed streams like `---\n---\nA\n` must produce the correct number of returned nodes in the correct order.