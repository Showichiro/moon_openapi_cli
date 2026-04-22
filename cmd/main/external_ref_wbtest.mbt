///|
test "resolve external local and remote reference locations" {
  assert_eq(
    resolve_local_ref("tests/fixtures/external_ref/root.json", "photo.json"),
    "tests/fixtures/external_ref/photo.json",
  )
  assert_eq(
    resolve_local_ref("tests/fixtures/external_ref/root.json", "../photo.json"),
    "tests/fixtures/photo.json",
  )
  assert_eq(
    resolve_remote_ref(
      "https://example.com/apis/openapi.json", "schemas/photo.json",
    ),
    "https://example.com/apis/schemas/photo.json",
  )
  assert_eq(
    resolve_remote_ref(
      "https://example.com/apis/v1/openapi.json", "../schemas/photo.json",
    ),
    "https://example.com/apis/schemas/photo.json",
  )
  assert_eq(
    resolve_remote_ref(
      "https://example.com/apis/openapi.json", "/schemas/photo.json",
    ),
    "https://example.com/schemas/photo.json",
  )
}

///|
async test "endpoint get resolves reachable local external refs" {
  let source = read_file("tests/fixtures/external_ref/root.json").unwrap()
  let options = @lib.endpoint_get_options(false)
  let resolved = resolve_endpoint_with_external_refs(
    source, "tests/fixtures/external_ref/root.json", "addPet", options,
  ).unwrap()
  assert_eq(resolved.warnings, [])
  guard resolved.subset.components is Some(Object(components))
  guard components.get("schemas") is Some(Object(schemas))
  assert_true(schemas.contains("NewPet"))
  assert_true(schemas.contains("Pet"))
  assert_true(schemas.contains("Photo"))
  assert_true(schemas.contains("PhotoMetadata"))
}

///|
async test "endpoint inline refs expands imported external refs" {
  let source = read_file("tests/fixtures/external_ref/root.json").unwrap()
  let options = @lib.endpoint_get_options(false, inline_refs=true)
  let resolved = resolve_endpoint_with_external_refs(
    source, "tests/fixtures/external_ref/root.json", "addPet", options,
  ).unwrap()
  assert_eq(resolved.warnings, [])
  guard resolved.subset.operation is Object(operation)
  guard operation.get("requestBody") is Some(Object(request_body))
  guard request_body.get("content") is Some(Object(request_content))
  guard request_content.get("application/json") is Some(Object(request_media))
  guard request_media.get("schema") is Some(Object(request_schema))
  guard request_schema.get("properties") is Some(Object(request_props))
  guard request_props.get("photo") is Some(Object(photo_schema))
  assert_false(photo_schema.contains("$ref"))
  guard photo_schema.get("properties") is Some(Object(photo_props))
  guard photo_props.get("metadata") is Some(Object(metadata_schema))
  assert_false(metadata_schema.contains("$ref"))
  assert_eq(metadata_schema.get("type"), Some(Json::string("object")))
}

///|
async test "endpoint no-resolve skips external ref resolution" {
  let source = read_file("tests/fixtures/external_ref/root.json").unwrap()
  let options = @lib.endpoint_get_options(true)
  let resolved = resolve_endpoint_with_external_refs(
    source, "tests/fixtures/external_ref/root.json", "addPet", options,
  ).unwrap()
  assert_eq(resolved.warnings, [])
  assert_true(resolved.subset.components is None)
}

///|
async test "schema get resolves reachable local external refs" {
  let source = read_file("tests/fixtures/external_ref/root.json").unwrap()
  let options = @lib.schema_get_options(false)
  let resolved = resolve_schema_with_external_refs(
    source, "tests/fixtures/external_ref/root.json", "Pet", options,
  ).unwrap()
  assert_eq(resolved.warnings, [])
  guard resolved.subset.components is Some(Object(components))
  guard components.get("schemas") is Some(Object(schemas))
  assert_true(schemas.contains("Pet"))
  assert_true(schemas.contains("NewPet"))
  assert_true(schemas.contains("Photo"))
  assert_true(schemas.contains("PhotoMetadata"))
}
