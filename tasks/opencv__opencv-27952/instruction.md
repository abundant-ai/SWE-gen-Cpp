`cv::findTransformECC` currently only accepts an input mask for the moving image (the “image” argument). This is insufficient for common alignment scenarios where different pixels are valid/invalid in the template and the image (e.g., moving foreground objects, partial overlap, or regions to exclude only in the template). With only a single mask, pixels invalid in the template can still influence the optimization, and pixels masked in one frame but not the other can still degrade convergence and accuracy.

Extend `cv::findTransformECC` by adding a new overload that accepts an additional `templateMask` so that the ECC optimization uses only pixels that are valid in both the template and the image. Backward compatibility must be preserved: existing function signatures must continue to work unchanged, and their behavior must remain consistent with previous releases when `templateMask` is not provided.

The new overload should have the form (names and types as in OpenCV conventions):

```cpp
double cv::findTransformECC(
    InputArray templateImage,
    InputArray inputImage,
    InputOutputArray warpMatrix,
    int motionType,
    TermCriteria criteria,
    InputArray inputMask,
    int gaussFiltSize,
    InputArray templateMask);
```

Expected behavior:
- When both `inputMask` and `templateMask` are provided, only pixels that are non-zero in both masks (after accounting for the current warp during iterative alignment) should contribute to the ECC cost function and parameter updates.
- The masking must be applied consistently throughout the optimization (including any internal image/gradient preparation), so that excluded regions do not affect convergence.
- If `templateMask` is empty/not provided, results should match the existing behavior that only uses `inputMask`.
- If `inputMask` is empty/not provided but `templateMask` is provided, alignment should still work and should exclude template regions marked invalid.
- If the intersection of valid pixels becomes empty (or too small to proceed meaningfully), the function should fail in the same style as existing invalid-input situations (e.g., by throwing an OpenCV error) rather than producing undefined results.

A minimal usage example that should work:

```cpp
cv::Mat warp = cv::Mat::eye(2, 3, CV_32F);
cv::TermCriteria crit(cv::TermCriteria::COUNT + cv::TermCriteria::EPS, 50, 1e-6);

// templateMask excludes a region only in the template; inputMask excludes a region only in the input image.
double cc = cv::findTransformECC(templateImg, inputImg, warp,
                                cv::MOTION_AFFINE, crit,
                                inputMask, 5, templateMask);
```

The goal is that alignment remains robust in the presence of independently moving artifacts and template-only invalid regions by relying on the intersection of valid pixels across both masks.