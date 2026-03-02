When using cpp-httplib in non-header-only mode (splitting into a .h + .cc using the provided split script), programs that call certain templated member functions can compile but fail to link. The implementations of these templates end up in the generated .cc file, but because they are templates (and not explicitly instantiated for all used types), the linker cannot find the required symbols.

This shows up as unresolved symbol / undefined reference linker errors when a consumer calls templated APIs such as:

- `template <typename T> T Request::get_header_value(const char *key, size_t id = 0) const;`
- `template <typename T> T Response::get_header_value(const char *key, size_t id = 0) const;`
- `template <typename... Args> ssize_t Stream::write_format(const char *fmt, const Args &...args);`
- `template <class Rep, class Period> Server &Server::set_read_timeout(const std::chrono::duration<Rep, Period> &duration);`
- `template <class Rep, class Period> Server &Server::set_write_timeout(const std::chrono::duration<Rep, Period> &duration);`
- `template <class Rep, class Period> Server &Server::set_idle_interval(const std::chrono::duration<Rep, Period> &duration);`
- `template <typename T> T Result::get_request_header_value(const char *key, size_t id = 0) const;`
- `template <class Rep, class Period> void ClientImpl::set_connection_timeout(const std::chrono::duration<Rep, Period> &duration);`
- `template <class Rep, class Period> void ClientImpl::set_read_timeout(const std::chrono::duration<Rep, Period> &duration);`
- `template <class Rep, class Period> void ClientImpl::set_write_timeout(const std::chrono::duration<Rep, Period> &duration);`
- `template <class Rep, class Period> void Client::set_connection_timeout(const std::chrono::duration<Rep, Period> &duration);`
- `template <class Rep, class Period> void Client::set_read_timeout(const std::chrono::duration<Rep, Period> &duration);`
- `template <class Rep, class Period> void Client::set_write_timeout(const std::chrono::duration<Rep, Period> &duration);`

Expected behavior: A consumer should be able to split the library into a header and implementation file and then compile and link a program against those outputs without encountering undefined references for these templated APIs.

Actual behavior: After splitting, calling any of the above templates from a separate translation unit can produce linker failures because the template definitions are not available in the header at the point of instantiation.

Fix the split-build compatibility so that these templated methods work correctly when the library is used as a .h + .cc pair. The split output should be linkable even when the program includes the header in one compilation unit and links against the generated implementation object from another.

Additionally, ensure there is an automated check in the project that compiles and links code against the split outputs (without relying on header-only compilation) so regressions (e.g., forgetting an `inline` or moving a template definition into the .cc portion) are caught.