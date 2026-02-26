pugi::xml_document is currently not movable, which prevents idiomatic C++ code that returns documents by value or stores them in move-only contexts. Attempting to use move construction or move assignment (e.g., `pugi::xml_document b(std::move(a));` or `b = std::move(a);`) either fails to compile (no move operations) or falls back to copying behavior that is not intended/available. Implement proper move semantics for `pugi::xml_document` by adding a move constructor and move assignment operator.

After implementing move support, code like the following must be valid and behave correctly:

```cpp
pugi::xml_document make_doc()
{
    pugi::xml_document doc;
    doc.append_child("node");
    return doc; // should use move
}

void example()
{
    pugi::xml_document a;
    a.append_child("root");

    pugi::xml_node root_handle = a.first_child();

    pugi::xml_document b(std::move(a));

    // root_handle must remain valid and refer to the corresponding node now owned by b
    // so b should serialize to the same XML content as a had before the move.
}
```

The move operation must preserve the logical document contents in the destination document, and it must preserve validity of all existing node/attribute handles that referred to nodes in the moved-from document such that they now refer to the same underlying nodes now owned by the destination document. The one exception is the handle to the document node itself: a handle that specifically refers to the document node should not be expected to “become” the destination’s document node after the move.

Move construction/assignment should not perform deep copying of the XML tree; it should transfer ownership of the underlying storage and internal structures. It must work correctly for both empty documents and documents with parsed/appended content, and it must work for both move construction and move assignment.

The moved-from `xml_document` must remain in a valid, destructible state after the move, and subsequent operations on either document must not result in crashes, use-after-free, double-free, or corrupted trees. If exceptions are enabled, moves should not allocate in typical configurations; however, in configurations where internal structures may need growth (e.g., compact mode), move may throw (e.g., due to allocation failure) and must provide well-defined behavior consistent with C++ move requirements (no corruption/leaks, destination/moved-from objects remain valid).