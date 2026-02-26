XPath queries that produce node sets with potential duplicates can return results in an unstable order across different runs of the same program. This is most visible when using the union operator (`|`) in an XPath expression.

Currently, when evaluating unions, the engine removes duplicate nodes/attributes by sorting the intermediate sequence using pointer values and then dropping consecutive duplicates. Because pointer values depend on memory allocation patterns, this makes the final `xpath_node_set` ordering effectively dependent on allocator behavior and can vary from run to run. In practice this can cause intermittent and hard-to-reproduce bugs where repeated evaluation of the same XPath expression over the same document yields different result sequences.

Reproduction example: given an XML where some nodes are optional (e.g., elements like `DESCRIPTION_SHORT` always present and `EAN` optionally present under the same parent), selecting both with a union-like selection should always preserve a consistent interleaving based on the encounter/collection order. Instead, repeated selection may sometimes reorder parts of the result so that some `EAN` nodes appear earlier/later than expected. Users have observed that running the same query in a loop can sometimes yield a different node count/order in some iterations.

The duplicate-removal step must be changed so that it does not reorder the node set. When duplicates are removed from an unsorted `xpath_node_set` produced by operations like union, the algorithm should preserve the original sequence order (stable filtering): keep the first occurrence of each node/attribute and remove later duplicates, without performing a pointer-based sort. After this change, evaluating the same XPath query repeatedly over the same document must always produce the same ordered `xpath_node_set`.

The fix should ensure stable results for:
- Union expressions such as `child/subchild[@id=1] | child/subchild[@id=2]`.
- More complex unions that mix nodes, attributes, the context node (`.`), and text nodes, e.g. `child1 | child2 | child1/@* | . | child2/@* | child2/text()`.

Sorting behavior via `xpath_node_set::sort(bool reverse)` must continue to work as before (both normal and reverse document order), but the intermediate duplicate removal performed during evaluation should no longer introduce non-deterministic ordering.