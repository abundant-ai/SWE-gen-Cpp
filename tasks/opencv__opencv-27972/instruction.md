In OpenCV, an empty matrix (Mat/UMat with no elements) should be treated as having an undefined type. Currently, some operations unintentionally preserve or “leak” a previously allocated destination type when the operation produces an empty result. This makes user code incorrectly rely on dst.type() even when dst is empty, and can cause inconsistent behavior between Mat and UMat paths.

Update the core behavior so that, after an operation that results in an empty output, the output matrix’s type is forced to “empty/undefined” rather than retaining any prior type. In practice, if an output is empty, querying its type should not return an old non-empty type that happened to be stored in the destination from earlier use.

This should be enforced consistently for both cv::Mat and cv::UMat outputs across relevant APIs that may validly return empty outputs (for example, operations that can produce zero-sized results or that early-exit without producing data).

There are two explicit API exceptions where the output type is defined even if the result is empty:

- cv::Mat::copyTo (and the corresponding UMat overloads): copyTo is documented to re-create the output buffer and set its type based on the source, so dst should have the source type after copyTo even if the copied result is empty.
- cv::Mat::convertTo / cv::UMat::convertTo: convertTo takes an explicit output type/depth parameter, so the output type is defined by that parameter even if the result is empty.

Expected behavior:
- For operations other than the exceptions above, if the resulting dst is empty, dst’s type should be treated as undefined (i.e., it should not preserve any previous non-empty type).
- For copyTo, dst’s type should be set according to the source type.
- For convertTo, dst’s type should be set according to the requested output type.

Actual behavior to fix:
- Some APIs leave dst empty but with a stale, previously allocated type, leading to inconsistent and misleading dst.type() results when dst.empty() is true.

Reproduction example (conceptual):
1) Create a destination matrix with a non-empty type (e.g., CV_8UC3).
2) Call an API that produces an empty output into that destination.
3) Observe that dst.empty() is true but dst.type() still reports CV_8UC3.

After the fix, in step (3) dst should be empty with no retained prior type, unless the API is copyTo or convertTo where the output type is explicitly defined as described above.