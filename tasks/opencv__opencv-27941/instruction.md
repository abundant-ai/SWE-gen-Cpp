OpenCV’s new DNN engine is missing support for the Discrete Fourier Transform (DFT) operation, so models that include a DFT node cannot be executed with this engine. When importing and running ONNX networks that contain a DFT/FFT-style operator (commonly represented in ONNX as an operator that performs a forward or inverse transform over one or more axes, potentially with options like normalization and onesided output), the network either fails during layer creation or fails at runtime because there is no corresponding layer implementation in the new engine.

The DNN engine must provide a DFT layer implementation and integrate it into the engine’s layer factory/registry so that a DFT node can be parsed/constructed and executed as part of a DNN graph.

Expected behavior:
- Loading an ONNX model containing a DFT/FFT operator should successfully create the network without errors about an unknown/unsupported layer.
- Running inference should produce numerically correct outputs for DFT, including correct handling of real/complex representation as used by the importer (e.g., complex numbers represented as an extra last dimension of size 2 for real/imag components).
- The implementation should correctly support the key attributes/inputs typically used by ONNX DFT-like ops:
  - Forward and inverse transform modes.
  - Configurable axes (including negative axis indices) and behavior when axes are omitted.
  - Optional normalization modes (e.g., “backward/forward/ortho” semantics) if exposed by the operator.
  - Shape rules consistent with the operator definition (including preserving non-transformed dimensions and producing expected output rank).

Actual behavior (current):
- The new engine cannot execute these graphs because the DFT operation is not implemented/registered, leading to failures such as inability to create the layer instance for the corresponding ONNX node, or runtime execution errors when the engine encounters the unimplemented operation.

Implement/ensure:
- A DFT layer exists in the new engine with correct forward execution.
- The ONNX importer (or the engine’s internal graph conversion) maps the ONNX DFT-like operator to this new DFT layer.
- The layer supports CPU execution at minimum (and any other targets supported by the new engine if applicable), with correct output for representative transforms (1D/2D over various axes, different signal sizes, and inverse transforms).