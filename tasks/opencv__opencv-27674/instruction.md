The new DNN engine does not support the ONNX NonMaxSuppression (NMS) operator, so ONNX models that include NMS either fail to import/run or must be excluded from conformance execution. Add an NMS layer implementation to the new DNN engine so that networks containing NonMaxSuppression can be parsed and executed successfully.

When an ONNX model includes NonMaxSuppression, importing or running the network with the new engine currently results in an unsupported-layer failure (e.g., inability to create the layer instance for the ONNX node) or produces incorrect outputs compared to expected NMS behavior. After the fix, NonMaxSuppression must be recognized by the ONNX importer and executed by the new engine as a first-class layer.

The NMS layer must implement standard ONNX NonMaxSuppression semantics:
- Inputs: boxes, scores, and optional parameters (max_output_boxes_per_class, iou_threshold, score_threshold) according to ONNX conventions.
- Output: selected indices (typically a 2D tensor of triplets identifying batch index, class index, and box index) consistent with ONNX expectations.
- Behavior: perform per-class (and per-batch) suppression using IoU thresholding; respect score_threshold filtering; cap the number of returned boxes per class using max_output_boxes_per_class.
- Type/shape handling: accept typical float inputs for boxes/scores and produce indices in the expected integer type; handle dynamic/variable shapes as used by ONNX NMS.

The implementation should be integrated into the new DNN engine so that:
- Layer creation works during import (the layer is constructible and does not trigger “can’t create layer” style errors).
- Shape inference/memory shape calculation for the layer is correct so the network can be compiled.
- Execution produces stable, deterministic results matching ONNX NMS output formatting.

If the engine cannot support some optional modes/attributes, it should fail with a clear, specific error message describing the unsupported configuration, rather than a generic layer creation failure.