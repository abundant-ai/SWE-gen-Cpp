Java validation errors currently expose only the generated/compiled field identifier (or otherwise omit the original proto field name). This is a problem when converting validation failures into structured RPC error details (for example `google.rpc.BadRequest`), because clients expect the `BadRequest.FieldViolation.field` value to match the field name as written in the `.proto` definition.

When a validator throws `io.envoyproxy.pgv.ValidationException`, the resulting gRPC error produced by `io.envoyproxy.pgv.grpc.ValidatingServerInterceptor` and `io.envoyproxy.pgv.grpc.ValidatingClientInterceptor` should include a `com.google.rpc.Status` with `BadRequest` details, where each `BadRequest.FieldViolation` includes the proto field name.

Reproduction scenario:
- A unary RPC is invoked with a request message that fails validation.
- The validator implementation throws `new ValidationException("one", "", "is invalid")` (i.e., the exception’s field name is set to `"one"`).

Expected behavior:
- The RPC fails with a `io.grpc.StatusRuntimeException`.
- The exception’s trailers include a `com.google.rpc.Status` (extractable via `io.grpc.protobuf.StatusProto.fromThrowable(...)`).
- The embedded `BadRequest` detail (unpackable from the `Status` details) contains a `FieldViolation` whose `field` equals the proto field name provided by the validation failure (e.g., `"one"`), and whose `description` reflects the validation message (e.g., contains `"is invalid"`).

Actual behavior:
- The generated `BadRequest.FieldViolation.field` does not contain the proto field name (it may be empty, or contain only a generated/Java-specific identifier), which makes it unsuitable for constructing user-facing RPC validation errors keyed by proto field.

Implement support so that proto field names propagate through `ValidationException` handling into the gRPC `BadRequest` error details consistently for both client-side and server-side interceptors, including when validators are obtained through `io.envoyproxy.pgv.ReflectiveValidatorIndex` as well as custom `io.envoyproxy.pgv.ValidatorIndex` implementations.