Loading certain TensorFlow/ONNX networks that contain Batch Normalization nodes fails in OpenCV DNN due to missing/incorrect BatchNormalization support in the new DNN engine. This prevents common models (e.g., EfficientNet variants exported from Keras via TensorFlow or converted to ONNX) from being imported and executed.

A typical failure when importing a TensorFlow frozen graph that contains a fused batch norm looks like:

```
error: (-2:Unspecified error) Input [batch_normalization_1/cond/ones_like] for node [batch_normalization_1/cond/FusedBatchNorm] not found in function 'getConstBlob'
```

When importing some graphs, layer creation can also fail earlier during network construction with an error of the form:

```
error: (-2:Unspecified error) Can't create layer ".../Max" of type "Max" in function 'getLayerInstance'
```

For ONNX models (including those produced by tf2onnx), BatchNorm patterns may be represented in a way that currently triggers parsing/creation errors during ONNX import, preventing the network from loading.

The DNN module should support BatchNormalization as a first-class layer in the new engine so that networks containing BatchNorm can be imported successfully and executed. In particular:

- Importing ONNX graphs containing BatchNormalization (and equivalent fused variants from TF/ONNX conversion pipelines) should not crash or throw during parsing/construction.
- The implementation must correctly apply BatchNorm semantics (scale, bias, running mean, running variance, epsilon) so that inference results match expected outputs within typical floating-point tolerances.
- BatchNormalization must work in typical NCHW inference usage in OpenCV DNN and integrate with the rest of the engine so it can be fused/handled consistently alongside convolution and activation layers.

After the fix, ONNX conformance coverage should include BatchNormalization without requiring it to be globally denied/filtered due to missing support, and models like EfficientNet exported from Keras should load without the above exceptions.