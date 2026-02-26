Arrow’s Ruby ArrowFormat layer currently can’t preserve user-defined custom metadata on schema and field objects when writing to disk and reading back. As a result, metadata attached to a field or a schema is lost after a write/read roundtrip.

Add support for custom metadata on both Field and Schema in the Ruby ArrowFormat API.

When creating a field and attaching metadata, the metadata must be retrievable via a reader after serialization:

```ruby
field = Arrow::Field.new("value", :boolean).with_metadata(
  "key1" => "value1",
  "key2" => "value2"
)

schema = Arrow::Schema.new([field])
record_batch = Arrow::RecordBatch.new(schema, {"value" => [true, nil, false]})

# After saving and reading back, the field metadata must be preserved
read_schema = reader.schema
read_schema.fields[0].metadata
# => {"key1"=>"value1", "key2"=>"value2"}
```

Similarly, when attaching metadata to a schema, it must be preserved after serialization:

```ruby
field = Arrow::Field.new("value", :boolean)
schema = Arrow::Schema.new([field]).with_metadata(
  "key1" => "value1",
  "key2" => "value2"
)

record_batch = Arrow::RecordBatch.new(schema, {"value" => [true, nil, false]})

# After saving and reading back, the schema metadata must be preserved
read_schema = reader.schema
read_schema.metadata
# => {"key1"=>"value1", "key2"=>"value2"}
```

This requires:

- Adding `ArrowFormat::Field#metadata` and `ArrowFormat::Schema#metadata` accessors (or equivalent public API) so metadata is available on the format objects.
- Ensuring writing logic serializes field and schema custom metadata into the Arrow IPC schema/field metadata representation.
- Ensuring reading logic parses the stored custom metadata back into the corresponding `metadata` hashes.

Expected behavior: metadata key/value pairs set via `with_metadata` on `Arrow::Field` and `Arrow::Schema` roundtrip through IPC writing/reading unchanged, and `metadata` returns a Ruby hash containing the same string keys and values.

Actual behavior (before the fix): `schema.metadata` and/or `schema.fields[i].metadata` is `nil`/empty or missing entries after reading back data that was written with metadata.