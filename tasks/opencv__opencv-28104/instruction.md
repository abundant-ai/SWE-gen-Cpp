OpenCV DNN cannot correctly run ONNX models that use the RMSNormalization (RMSNorm) operator. When importing such a model via the ONNX frontend and running it with the CPU backend, model loading and/or inference fails (commonly as an unsupported layer/operator) or produces incorrect output compared to ONNX reference behavior.

Implement RMSNormalization operator support end-to-end so that ONNX graphs containing RMSNormalization can be imported and executed on CPU.

The operator semantics must match ONNX RMSNormalization:

- Inputs:
  - X: floating point tensor.
  - Scale: 1D tensor applied as per-channel scaling along the normalization axis.
- Attributes:
  - axis: the axis (typically last dimension) over which RMS normalization is computed.
  - epsilon: small constant added to the mean square for numerical stability.

Expected computation for each slice along the chosen axis:

1) Compute mean_square = mean(X^2) over the normalization axis.
2) Compute inv_rms = 1 / sqrt(mean_square + epsilon).
3) Normalize: Y = X * inv_rms.
4) Apply scale (broadcasted appropriately): Y = Y * Scale.

Behavioral requirements:

- Importing an ONNX model containing RMSNormalization must succeed without reporting an unknown/unsupported layer.
- CPU inference must produce numerically correct outputs for typical shapes used by transformer blocks, including:
  - 2D [N, H] and 3D [B, T, H] inputs.
  - Non-trivial axis values (including negative axis values that refer to dimensions from the end).
  - Broadcasting of Scale must work correctly for the normalization axis dimension.
- Epsilon must be respected; outputs should remain finite for inputs containing zeros.
- Type support: at minimum float32 must be correct. If float16 is accepted by the importer, it must either execute correctly or be rejected with a clear error; it must not silently produce wrong results.

After implementation, ONNX conformance runs that previously had to skip/deny RMSNormalization-related cases should be able to execute successfully on the CPU target with outputs matching expected tolerances.