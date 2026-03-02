Crow’s Mustache templating currently does not implement Mustache “lambdas” (optional feature in the Mustache spec). When a template references a key whose value is a callable/lambda, rendering should invoke the lambda and use its return value in the output, but today lambdas are treated like unsupported types (or ignored/serialized incorrectly), so templates that rely on lambda behavior cannot be rendered correctly.

Add Mustache lambda support with value expansion.

When rendering a template with a context that provides a lambda for a tag, the renderer must:

- For variable tags like `{{name}}`, if `name` resolves to a lambda, the lambda should be invoked and its returned string should be inserted into the output as the value of `{{name}}`.
- For section tags like `{{#name}}...{{/name}}`, if `name` resolves to a lambda, the lambda should be invoked with the unrendered section content (the literal text inside the section). The lambda’s return value must then be treated as Mustache template text and rendered (“value expansion”) against the current context before being appended to the output.

This should follow standard Mustache lambda semantics:

- The lambda result for sections must be re-parsed/re-rendered so that any Mustache tags produced by the lambda are expanded using the current context.
- The lambda should behave correctly when nested within other sections or when it produces content containing `{{...}}` placeholders.
- Normal non-lambda behavior (strings, booleans, lists, objects) must remain unchanged.

Currently, attempting to use a lambda in the context results in incorrect output (the lambda is not executed) and prevents conforming Mustache templates (that depend on lambdas) from rendering as specified. Implement the missing lambda execution and expansion so that templates using lambdas render to the expected final string output without errors.