OpenCV DNN cannot correctly import and run ONNX models that use the standard ONNX operator `Attention` (opset 23). Attempting to load or execute such a model either fails during ONNX parsing (operator unsupported) or produces incorrect outputs for common Attention configurations.

Add support for the ONNX `Attention` operator so that `cv::dnn::readNetFromONNX()` can successfully load graphs containing `Attention`, and `cv::dnn::Net::forward()` produces numerically correct results.

The implementation must handle the operator attributes and input combinations defined by the ONNX spec for `Attention`, including:

- Inputs representing Q/K/V and optional `attn_mask`.
- Both 3D and 4D tensor forms used by ONNX Attention models (typical shapes correspond to batched sequences and multi-head layouts).
- Support for different numbers of query heads vs key/value heads (grouped-query attention / GQA), where K/V head count can be smaller than Q head count.
- Support for causal attention (triangular masking behavior) when requested by the operator configuration.
- Correct application of scaling (when a scale is provided or implied by head size) and optional “softcap” behavior where logits are capped before softmax (as used by some ONNX Attention test models).
- Correct handling of `attn_mask` across common mask ranks and types, including boolean masks, and broadcast behavior consistent with the operator definition.

Expected behavior:

- Loading an ONNX model containing `Attention` should not error due to an unrecognized layer/operator.
- Forward inference should match reference outputs for cases such as:
  - 3D attention with and without an attention mask
  - 3D causal attention
  - Different head-size configurations (including mixed/unequal head sizes where applicable)
  - Grouped-query attention (different Q heads vs K/V heads), with and without masks/causal behavior
  - Scaled attention and softcapped attention variants
  - 4D attention inputs, including attention masks of varying ranks (e.g., mask as 3D or 4D) and boolean masks

If GPU backends do not yet support this operator or specific data types/shapes, the behavior should be consistent and not crash: either run correctly on the backend or cleanly fall back to CPU execution without producing incorrect results.