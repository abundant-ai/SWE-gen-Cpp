When including both the range formatting support and the standard-library formatting support, formatting a `std::filesystem::path` fails to compile on Microsoft Visual Studio (notably VS 2019/2022 in C++17 mode). A minimal reproduction is:

```cpp
#include "fmt/ranges.h"
#include "fmt/std.h"

int main() {
  std::filesystem::path p("data/somewhat");
  fmt::format("Path={}", p);
}
```

On MSVC this triggers an ambiguity error during template instantiation:

```
error C2752: 'fmt::formatter<std::filesystem::path,char,void>': more than one partial specialization matches the template argument list
... could be 'fmt::formatter<R,Char,std::enable_if<fmt::is_range<T,Char>::value,void>::type>'
... or       'fmt::formatter<std::filesystem::path,Char,void>'
```

The library should compile cleanly when both headers are included and should select the dedicated filesystem-path formatter rather than treating `std::filesystem::path` as a generic range.

After the fix, the following behaviors must work (when `std::filesystem` is available and the compiler is MSVC new enough to support the resolution):

- `fmt::format("{:8}", std::filesystem::path("foo"))` must produce `"foo"   ` (including the quotes and padding to width 8).
- `fmt::format("{}", std::filesystem::path("foo\"bar.txt"))` must produce `"foo\\\"bar.txt"` (i.e., the output is quoted, and an embedded `"` in the path is escaped in the formatted string).
- On Windows, formatting a wide-character `std::filesystem::path` containing non-ASCII characters must produce the corresponding UTF-8 byte sequence in the resulting `std::string`.
- Formatting a mix of a `std::filesystem::path` and an unrelated range type must work without ambiguity, e.g.:

```cpp
auto p = std::filesystem::path("foo/bar.txt");
auto c = std::vector<std::string>{"abc", "def"};
fmt::format("path={}, range={}", p, c);
```

and should return:

```
path="foo/bar.txt", range=["abc", "def"]
```

In short: ensure `fmt::formatter<std::filesystem::path, Char>` is unambiguous even when range formatting is enabled, and keep the existing semantics of quoting/escaping for paths intact across platforms (including Windows Unicode paths).