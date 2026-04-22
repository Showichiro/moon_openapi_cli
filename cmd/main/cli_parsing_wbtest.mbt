///|
test "resolve warning format rejects unsupported value" {
  let argv = ["endpoint", "get", "addPet", "--warnings", "yaml"]
  let parsed : Result[@argparse.Matches, _] = try? command().parse(argv~)
  guard parsed is Ok(root_matches)
  guard root_matches.subcommand is Some(("endpoint", endpoint_matches))
  guard endpoint_matches.subcommand is Some(("get", get_matches))
  assert_true(
    resolve_warning_format(get_matches)
    is Err(@lib.ApispecError::UsageError("unsupported warnings: yaml")),
  )
}

///|
test "format option parser supports md and rejects unsupported value" {
  let argv = ["endpoint", "get", "addPet", "--format", "md"]
  let endpoint_parsed : Result[@argparse.Matches, _] = try? command().parse(
    argv~,
  )
  guard endpoint_parsed is Ok(endpoint_root_matches)
  guard endpoint_root_matches.subcommand is Some(("endpoint", endpoint_matches))
  guard endpoint_matches.subcommand is Some(("get", endpoint_get_matches))
  assert_true(
    resolve_get_format(endpoint_get_matches)
    is Ok(@lib.EndpointGetFormat::EndpointGetMarkdown),
  )
  let argv = ["schema", "get", "Pet", "--format", "yaml"]
  let schema_parsed : Result[@argparse.Matches, _] = try? command().parse(argv~)
  guard schema_parsed is Ok(schema_root_matches)
  guard schema_root_matches.subcommand is Some(("schema", schema_matches))
  guard schema_matches.subcommand is Some(("get", schema_get_matches))
  assert_true(
    resolve_schema_get_format(schema_get_matches)
    is Err(@lib.ApispecError::UsageError("unsupported format: yaml")),
  )
}

///|
test "search query accepts multiple positional words" {
  let argv = ["endpoint", "search", "create", "pet", "--limit", "3"]
  let parsed : Result[@argparse.Matches, _] = try? command().parse(argv~)
  guard parsed is Ok(root_matches)
  guard root_matches.subcommand is Some(("endpoint", endpoint_matches))
  guard endpoint_matches.subcommand is Some(("search", search_matches))
  assert_true(joined_positional(search_matches, "query") is Ok("create pet"))
  assert_true(resolve_limit(search_matches) is Ok(3))
}

///|
test "search format honors quiet flag" {
  let argv = ["schema", "search", "pet", "--quiet"]
  let parsed : Result[@argparse.Matches, _] = try? command().parse(argv~)
  guard parsed is Ok(root_matches)
  guard root_matches.subcommand is Some(("schema", schema_matches))
  guard schema_matches.subcommand is Some(("search", search_matches))
  assert_true(
    resolve_schema_search_format(search_matches)
    is Ok(@lib.SchemaSearchFormat::SchemaSearchQuiet),
  )
}

///|
test "resolve limit rejects unsupported value" {
  let argv = ["endpoint", "search", "pet", "--limit", "zero"]
  let parsed : Result[@argparse.Matches, _] = try? command().parse(argv~)
  guard parsed is Ok(root_matches)
  guard root_matches.subcommand is Some(("endpoint", endpoint_matches))
  guard endpoint_matches.subcommand is Some(("search", search_matches))
  assert_true(
    resolve_limit(search_matches)
    is Err(@lib.ApispecError::UsageError("unsupported limit: zero")),
  )
}
