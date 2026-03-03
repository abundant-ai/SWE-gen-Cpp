Importing ONNX models that contain the `RandomNormalLike` operator fails in OpenCV DNN on CPU with an assertion error during shape inference. When `readNetFromONNX()` (or equivalent ONNX import) processes a `RandomNormalLike` node with one input and one output, model loading/initialization throws an exception similar to:

```
Node [RandomNormalLike@ai.onnx] parse error: ... error: (-215:Assertion failed) requiredOutputs == 1 in function 'getMemoryShapes'
```

This prevents ONNX networks using `RandomNormalLike` from being imported and executed.

The `RandomNormalLike` layer should support the standard ONNX behavior: given a single input tensor `X`, it produces a single output tensor `Y` that has the same shape as `X`. The output element type should be correct and consistent with the ONNX `dtype` attribute semantics for `RandomNormalLike`:

- If the ONNX node specifies `dtype`, the produced output should use that data type.
- If `dtype` is not specified, the output type should default appropriately (matching ONNX expectations) rather than causing a mismatch or triggering internal assertions.

After the fix, ONNX models containing `RandomNormalLike` should import successfully and run without throwing, including cases where the input has a basic shape and cases with more complex (multi-dimensional) shapes. The layer’s shape/type inference must not assert for valid `RandomNormalLike` nodes with exactly one output, and the produced output tensor must have the same shape as the input tensor with the expected floating-point output type (and correct handling of the `dtype` override when present).