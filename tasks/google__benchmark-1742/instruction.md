When emitting benchmark results in JSON format, the top-level "context" block is missing explicit versioning information needed by tooling to identify the library build and JSON schema compatibility. JSON consumers need the output to include both the benchmark library’s version/build info and the JSON schema version so they can safely parse and evolve the format.

Update the JSON reporter so that the "context" object includes these fields:
- "library_version": a string representing the benchmark library version (it must always be present in JSON output).
- "library_build_type": a string representing the build type of the library (e.g., derived from how the library was built; it must always be present in JSON output).
- "json_schema_version": an integer schema version identifier (currently expected to be 1).

These fields must appear in the JSON output under "context" alongside the existing metadata (date, host_name, executable, num_cpus, mhz_per_cpu, caches, load_avg, etc.). The output must remain valid JSON, and the new keys must be emitted consistently for all runs that use JSON reporting.

Example (illustrative):
{
  "context": {
    "date": "...",
    "host_name": "...",
    ...,
    "library_version": "...",
    "library_build_type": "...",
    "json_schema_version": 1
  },
  "benchmarks": [ ... ]
}

Currently, JSON output does not include one or more of these fields, causing downstream tooling to be unable to detect the schema/library version reliably. After the change, generating JSON output should always include all three keys in the context block with the correct types (strings for the first two, integer for the schema version).