The formatting library currently unconditionally references C++ iostream-related headers/types (e.g., <istream>, <ostream>, <sstream> and stream operators), which prevents using the library in environments where stream support is unavailable or intentionally excluded (for smaller builds or restricted standard library configurations). Attempting to include the main public header(s) and use core formatting facilities should be possible without pulling in any *stream headers.

Add support for making iostream integration optional via a preprocessor switch. When a user defines `FMT_NO_STREAM_LIBRARIES` before including the library headers, the library must compile cleanly without referencing iostream facilities.

Example expected to compile:

```cpp
#define FMT_NO_STREAM_LIBRARIES
#include <format.h>

int main() {
  auto s = fmt::format("{} {}", 1, "x");
}
```

With `FMT_NO_STREAM_LIBRARIES` defined, code paths that rely on streaming (such as formatting arbitrary types through `operator<<`, stream-based conversions, or any overloads that require `std::basic_ostream` / `std::basic_istream` / `std::basic_stringstream`) must be excluded so that including the headers does not require any of the stream headers.

When `FMT_NO_STREAM_LIBRARIES` is not defined (default behavior), existing stream-related formatting behavior must remain available and unchanged.

The change should ensure that common writer/formatter usage continues to work in no-stream mode (e.g., `fmt::BasicMemoryWriter` streaming-like insertion of supported primitive/string types into the writer, and `fmt::format(...)` for standard supported types), while any optional iostream-dependent functionality is either disabled at compile time or not declared/instantiated so builds succeed without stream headers.