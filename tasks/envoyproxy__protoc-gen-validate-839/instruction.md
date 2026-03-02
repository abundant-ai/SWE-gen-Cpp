Generating Go validation code fails to correctly import and reference enum types when a .proto file uses enums from multiple external packages that share the same last path segment / Go package name (e.g., both end in `v1`), or when enums are referenced in different rule contexts (`enum.in`, `enum.not_in`, and nested/repeated/map rule variants). In these scenarios the generated `.pb.validate.go` can reference an import alias that was never declared, causing `go vet ./...` (and compilation) to fail with errors like:

```
vet: <generated>.pb.validate.go:<line>:<col>: undeclared name: v1
```

A minimal reproduction is a proto that imports two different packages with the same Go package identifier and then applies enum validation rules to fields from both packages, for example:

```proto
import "foo/v1/datatype.proto";
import "bar/v1/datatype.proto";

message CreateSomethingRequest {
  foo.v1.Foo.FooType foo_type = 1 [(validate.rules).enum = {in: [1, 2, 3, 4]}];
  bar.v1.Bar.BarType bar_type = 2 [(validate.rules).enum = {not_in: [1, 2, 3, 4]}];
}
```

Expected behavior:
- The Go validation code generator must emit a correct import section for all external enum types referenced by validation rules, even when multiple imports would naturally collide on the same package name.
- Any referenced package qualifier in generated code must correspond to an actually declared Go import (with a unique alias when necessary).
- The generator should avoid emitting duplicate imports or redundant aliases when multiple enum references resolve to the same Go import.
- This must work consistently for:
  - direct enum fields
  - nested external enums (e.g., `other_package.Embed.DoubleEmbed.DoubleEnumerated`)
  - repeated enum fields using `repeated.items.enum...`
  - map value enums using `map.values.enum...`
  - oneof-contained enum fields
  - both `enum.in` and `enum.not_in` (and `defined_only` / `const` variants), including when these different rules are used across different external packages.

Actual behavior:
- In at least some of the above scenarios, the generator produces code that refers to an undeclared import alias (commonly a short name like `v1`), leading to `go vet` failures and preventing consumers from compiling generated validators.

Fix the generator logic responsible for collecting/importing Go packages needed for enum validations so that:
- imports are deterministic and collision-safe across multiple external packages,
- generated enum validation expressions always use the correct, declared import alias,
- and duplicate/unused imports are not produced.