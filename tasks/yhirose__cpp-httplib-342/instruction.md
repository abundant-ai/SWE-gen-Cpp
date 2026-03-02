The server API supports serving static files by mapping URL prefixes to filesystem directories via `set_base_dir(...)` / mount-point style configuration. Currently, calling `set_base_dir()` can add new base directories at runtime, but there is no supported way to remove an existing mapping once it has been added. This makes it impossible to update or revoke previously configured mount points without restarting the server.

Add an API to remove a previously configured base directory mapping at runtime. The removal operation must be expressed in terms of the URL prefix (mount point), not the filesystem path, because the same directory may be mounted under multiple prefixes.

After implementing the removal API, these behaviors must be supported:

- A base directory can be added under a prefix (mount point) and then later removed by specifying that same prefix.
- Removing a mount point must stop the server from serving files for that prefix immediately (subsequent requests that previously resolved to the removed mount should no longer be served from that directory).
- If multiple mount points exist, removing one must not affect the remaining mount points.
- Removing a prefix that does not exist should not crash; it should return a clear success/failure result (or otherwise behave consistently and safely).

The API should be named along the lines of `remove_base_dir(prefix)` or `remove_mount_point(mount_point)` (the important part is that the parameter is the URL prefix/mount point). Ensure that using `set_base_dir()` to add mappings and then the new removal API to delete mappings works reliably during runtime while the server instance is in use.