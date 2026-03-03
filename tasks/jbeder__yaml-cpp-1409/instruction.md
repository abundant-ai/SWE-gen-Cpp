Iterating a YAML::Node can produce dangling references when code binds references to the iterator’s returned key/value objects. In particular, expressions like `node.begin()->first` and `iter->second` are exposed through an iterator proxy object that is a temporary. Taking a reference to `proxy.first` or `proxy.second` (directly or indirectly) can outlive that proxy temporary, leaving a `YAML::Node` reference that points into destroyed storage.

This manifests as nondeterministic behavior: sometimes the program appears to work (e.g., `Scalar()` returns the expected string), but under memory-poisoning conditions (custom allocators, ASAN, or just stack reuse) it can crash or produce invalid results. A minimal reproducer is:

```cpp
YAML::Node node;
node["key"] = "value";
const YAML::Node& invalid_node = node.begin()->first; // binds to iterator proxy temporary
std::string key_str = invalid_node.Scalar();          // use-after-free
```

A related real-world symptom is that iterating a map and binding `const YAML::Node& value = iter->second;` may later crash or throw when accessing nested keys (e.g., `value["b"]`) if intervening stack activity overwrites the proxy storage. Users have reported this as an “invalid node” / representation error appearing only in certain builds or when adding unrelated local variables.

The iterator behavior needs to be made safe/diagnosable: referencing `iterator->first` or `iterator->second` must not allow a `YAML::Node` to silently reference destroyed proxy storage. Either the API must ensure the returned objects remain valid for as long as standard iterator semantics imply, or the implementation must reliably invalidate/poison the proxy-backed `YAML::Node` objects when the proxy is destroyed so that incorrect lifetime extension fails deterministically rather than behaving nondeterministically.

After the fix, code that incorrectly stores `const YAML::Node&` obtained from `iterator->first`/`second` must no longer appear to “work sometimes”; it should be reliably detected (e.g., by crashing/aborting or otherwise failing deterministically), while correct usage—copying the `YAML::Node` value or otherwise not extending the proxy lifetime—must continue to work normally. The behavior should also be consistent when using non-standard STL allocators and under sanitizers.