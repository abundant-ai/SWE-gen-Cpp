YAML::Node currently provides remove(key) to delete entries from a node, but removing an element from a sequence by index does not work as expected. For example, given a sequence node, calling remove(1) should remove the element at index 1 and keep the node as a sequence, shifting subsequent elements left and reducing the size by one. Instead, remove(1) currently does nothing (or otherwise fails to behave like a sequence deletion), making it impossible to turn `[1, 2, 3]` into `[1, 3]` using the public API.

Fix YAML::Node::remove so that when the node is a sequence and the provided key is an integer index, it removes the element at that index. After removal, the node must still report IsSequence() == true, node.size() must decrease by 1, and remaining elements must be accessible by their new indices.

Examples of expected behavior:

```cpp
YAML::Node node;
node[0] = "a";
node[1] = "b";
node[2] = "c";
node.remove(1);
// Expected: sequence ["a", "c"]
// node.IsSequence() == true
// node.size() == 2
// node[0].as<std::string>() == "a"
// node[1].as<std::string>() == "c"
```

Removing the last element should also work:

```cpp
YAML::Node node;
node[0] = "a";
node[1] = "b";
node[2] = "c";
node.remove(2);
// Expected: sequence ["a", "b"]
```

This change must not break existing map removal behavior. Removing a string key from a map should still erase that entry:

```cpp
YAML::Node node;
node["foo"] = "bar";
node.remove("foo");
// Expected: node["foo"] is undefined/nonexistent
```

Additionally, if a node is a map (including maps that use integer keys), calling remove(1) must keep the node as a map (i.e., it must not accidentally convert the node to a sequence or otherwise change its type).