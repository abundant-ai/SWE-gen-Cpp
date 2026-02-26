pugi::xml_node is missing an efficient way to remove all attributes or all child nodes in one call. Today, users must repeatedly call xml_node::remove_attribute() or xml_node::remove_child() in a loop, which is both inconvenient and can be inefficient because single-item removal performs per-node relinking work that is unnecessary when deleting everything.

Add two new member functions on pugi::xml_node:

- xml_node::remove_attributes()
- xml_node::remove_children()

Both functions should remove all attributes/children from the node and leave the node itself intact.

Expected behavior:
- Calling remove_attributes() on a node that has attributes should remove every attribute, so that subsequent calls to node.first_attribute() return an empty xml_attribute and the serialized node contains no attributes.
- Calling remove_children() on a node that has child nodes (including element nodes, text/pcdata, comments, etc.) should remove every child node, so that subsequent calls to node.first_child() return an empty xml_node and the serialized node contains no child content.
- Calling either method on an empty node (no attributes / no children) should be a no-op and must not crash.
- Calling either method on an empty xml_node (default-constructed / null handle) should be safe and must not crash.

Example usage:

```cpp
pugi::xml_document doc;
doc.load_string("<node a='1'><child/><child2/></node>");

pugi::xml_node n = doc.child("node");

n.remove_attributes();
// doc should now serialize as: <node><child/><child2/></node>

n.remove_children();
// doc should now serialize as: <node/>
```

The methods must correctly update the internal DOM state so that normal navigation APIs (attribute iteration, child iteration, sibling relationships for remaining nodes, and serialization) behave consistently after the bulk removal.