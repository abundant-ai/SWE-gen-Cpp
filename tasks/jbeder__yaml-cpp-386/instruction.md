YAML map nodes do not currently behave consistently with document order when iterating and when emitting YAML back to a stream. This causes two classes of user-visible problems.

1) Downstream comparison failures when YAML is parsed and then compared/converted against another representation: a map entry can appear to be “missing” even though it exists in the input. In practice this shows up as unordered comparisons failing with messages like: One list is missing parameter: "coarse: max size". The underlying issue is that map traversal order is not stable relative to the document, so consumers that iterate maps (to build parameter lists, do merges, or compare structures) can observe inconsistent results.

2) Map order is not preserved when writing a YAML::Node back out: users load a YAML file, modify/add a key (e.g., config["lastLogin"] = ...), and then stream the node back to a file, but the keys come out in an unexpected/reordered way rather than the original document order. Users expect iterating a map node (via YAML::Node::begin()/end() and YAML::const_iterator) to visit key/value pairs in the same order as they appeared in the YAML document, and for the emitter to output map entries in that same order.

Fix YAML map nodes so that iterating a map (including const iteration) yields key/value pairs in document insertion order (the order the parser encountered them / the order they were inserted into the node). This order should be stable across runs and should be the order used by streaming/emitting a Node.

The following behaviors must hold:

- After parsing a YAML mapping, a for-loop over the node’s iterators visits entries in the same order as the input document.
- After programmatically inserting keys into a map node (e.g., node["a"]=1; node["b"]=2;), iteration yields "a" then "b".
- Operations like node.remove(key), node.force_insert(key, value), and accesses that create undefined entries (e.g., node["undefined"]; without assigning a value) must not corrupt iteration such that unrelated keys disappear or iteration count changes unexpectedly.
- Emitting a map node through the emitter/streaming operator should output keys in the same order that map iteration uses (document/insertion order).

Example scenario that should work reliably:

```cpp
YAML::Node n = YAML::Load("a: 1\nb: 2\nc: 3\n");
std::vector<std::string> keys;
for (auto it = n.begin(); it != n.end(); ++it) {
  keys.push_back(it->first.as<std::string>());
}
// keys must be {"a","b","c"}

n.remove("b");
// iteration must now yield {"a","c"} and n["a"], n["c"] must still be accessible.
```

Overall expected behavior: map nodes are iterated over in document order, and this order is the one used for output. Actual behavior today: map traversal/output order is not document-stable and can lead to missing/mis-compared parameters in downstream code and unexpected reordering when saving YAML.