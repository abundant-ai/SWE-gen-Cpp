Currently, YAML::Node::remove does not correctly remove items from sequence nodes when the index is provided as an integer key. For example, if a node represents a sequence (e.g., created via indexed assignment like node[0] = "a"; node[1] = "b"; node[2] = "c";), calling node.remove(1) should remove the element at index 1 and keep the node as a sequence, shifting subsequent elements down.

Reproduction example:

```cpp
YAML::Node node;
node[0] = "a";
node[1] = "b";
node[2] = "c";

node.remove(1);
```

Expected behavior:
- node remains a sequence (node.IsSequence() is true).
- node.size() becomes 2.
- node[0].as<std::string>() is "a".
- node[1].as<std::string>() is "c" (elements after the removed index shift left).

Another case that must work:

```cpp
YAML::Node node;
node[0] = "a";
node[1] = "b";
node[2] = "c";

node.remove(2);
```

Expected behavior:
- node remains a sequence.
- node.size() becomes 2.
- Remaining elements are "a", "b" in that order.

The existing map-removal behavior must remain correct and must not be broken:
- If node is a map (e.g., node["foo"] = "bar";), then node.remove("foo") should remove that key and node["foo"] should be undefined/falsey afterward.
- If node is a map with integer keys (e.g., node[1] = "hello"; node[2] = 'c'; plus other keys), calling node.remove(1) should remove key 1 while keeping the node a map (node.IsMap() remains true).

In short, YAML::Node::remove must support removing elements from sequences by index while preserving sequence type and correct element ordering, and it must continue to support removing keys from maps (including integer keys) without changing the node type.