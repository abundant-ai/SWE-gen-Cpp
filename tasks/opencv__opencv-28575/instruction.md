Several ONNX model executions in the DNN module fail shape validation in OpenCV 5.x due to incorrect handling of scalar tensors versus 1D tensors of length 1. After enabling stricter shape checks (ported from 4.x), outputs that are semantically compatible are treated as mismatched, causing failures like:

Expected equality of these values:
  shape(out)
    Which is: [<scalar>]
  shape(ref)
    Which is: [1]

This occurs in ONNX layer scenarios such as Gather producing a scalar result, ReduceMax producing a scalar, Einsum inner products, and dynamic-axes cases where an ONNX scalar may be represented as a 1-element 1D tensor on one side of the comparison.

The shape comparison/assertion logic used for validating DNN outputs (e.g., the helper that compares reference and computed outputs during tests) must treat these cases as compatible:

- A scalar shape and a 1D shape of length 1 should be considered equivalent for the purpose of shape assertions.
- This compatibility must work in both directions (ref is scalar, out is [1]; or ref is [1], out is scalar).

Additionally, input-shape validation performed via Net shape introspection (using Net::getLayerShapes with suggested input shapes/types) should not incorrectly fail when the network expects a scalar (0D) input but the provided input is represented as a 1D tensor with one element (or vice versa). When a scalar vs 1D-length-1 mismatch is the only difference, shape validation should not fail.

Expected behavior: Running ONNX DNN layer checks for models involving scalar outputs/inputs should pass shape assertions when only the scalar-vs-[1] representation differs.

Actual behavior: Shape assertions fail with mismatches like "[<scalar>]" vs "[1]" even though the tensors are effectively compatible.