The XPath parser and execution engine can consume unbounded C call stack space when given extremely deep XPath expressions (for example, deeply nested parentheses/brackets or other constructs that cause recursive parse/execution). This can lead to a stack overflow and process crash when compiling an XPath query via `pugi::xpath_query`.

The XPath implementation needs to enforce a maximum allowed AST/parse depth so that malicious inputs cannot create arbitrarily deep expression trees. When the depth limit would be exceeded during parsing (including cases where parsing is otherwise “stackless” but still builds an arbitrarily deep AST), the query compilation must fail gracefully instead of crashing. In these cases, constructing `pugi::xpath_query` with such an input should report a parsing failure (i.e., behave like other invalid XPath strings) and must not overflow the stack.

Expected behavior: for very deeply nested XPath expressions, `pugi::xpath_query` should fail to compile the expression and surface an XPath parsing error, without excessive recursion, without stack overflow, and without hanging.

Actual behavior: sufficiently deep/nested XPath inputs can cause unbounded recursion or downstream processing recursion, leading to stack overflow and a crash.

The fix should add depth tracking/limits at the points where XPath parsing can recurse and where deep AST nodes are created, so that the maximum supported depth is bounded and compilation fails cleanly once the limit is reached.