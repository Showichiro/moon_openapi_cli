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
