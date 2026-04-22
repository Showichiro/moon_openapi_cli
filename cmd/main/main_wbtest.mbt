///|
fn suggestion_openapi() -> String {
  (
    #|{
    #|  "openapi": "3.0.3",
    #|  "paths": {
    #|    "/pets": {
    #|      "post": {
    #|        "operationId": "addPet",
    #|        "responses": {
    #|          "201": {
    #|            "description": "created"
    #|          }
    #|        }
    #|      }
    #|    },
    #|    "/pets/{id}": {
    #|      "get": {
    #|        "operationId": "getPet",
    #|        "responses": {
    #|          "200": {
    #|            "description": "ok"
    #|          }
    #|        }
    #|      }
    #|    }
    #|  },
    #|  "components": {
    #|    "schemas": {
    #|      "Pet": {
    #|        "type": "object"
    #|      },
    #|      "Category": {
    #|        "type": "object"
    #|      }
    #|    }
    #|  }
    #|}
  )
}

///|
test "classify input source" {
  assert_true(classify_input_source("-") is Stdin)
  assert_true(
    classify_input_source("openapi.json") is LocalFile("openapi.json"),
  )
  assert_true(
    classify_input_source("http://example.com/openapi.json")
    is RemoteUrl("http://example.com/openapi.json"),
  )
  assert_true(
    classify_input_source("https://example.com/openapi.json")
    is RemoteUrl("https://example.com/openapi.json"),
  )
  assert_true(
    classify_input_source("ftp://example.com/openapi.json")
    is UnsupportedUrl("ftp"),
  )
  assert_true(
    classify_input_source("HTTPS://example.com/openapi.json")
    is UnsupportedUrl("HTTPS"),
  )
}

///|
test "closest candidate returns unique edit-distance match" {
  assert_eq(
    closest_candidate("addPett", ["listPets", "addPet"]),
    Some("addPet"),
  )
  assert_eq(closest_candidate("Pett", ["Category", "Pet"]), Some("Pet"))
}

///|
test "closest candidate rejects distant or tied matches" {
  assert_true(closest_candidate("abc", ["listPets"]) is None)
  assert_true(closest_candidate("abc", ["abd", "acc"]) is None)
}

///|
test "operation not found suggestion includes closest operation id" {
  let suggestion = endpoint_not_found_suggestion(
    "addPett",
    suggestion_openapi(),
    "openapi.json",
  )
  assert_true(suggestion.contains("did you mean 'addPet'?"))
  assert_true(
    suggestion.contains("apispec endpoint get addPet -f openapi.json"),
  )
  assert_true(suggestion.contains("apispec endpoint ls -f openapi.json"))
}

///|
test "schema not found suggestion includes closest schema name" {
  let suggestion = schema_not_found_suggestion(
    "Pett",
    suggestion_openapi(),
    "openapi.json",
  )
  assert_true(suggestion.contains("did you mean 'Pet'?"))
  assert_true(suggestion.contains("apispec schema get Pet -f openapi.json"))
  assert_true(suggestion.contains("apispec schema ls -f openapi.json"))
}

///|
test "not found suggestion falls back when candidates cannot be listed" {
  let suggestion = endpoint_not_found_suggestion("addPett", "[]", "broken.json")
  assert_false(suggestion.contains("did you mean"))
  assert_eq(
    suggestion, "run `apispec endpoint ls -f broken.json` to inspect available operations",
  )
}

///|
test "format warnings as text by default shape" {
  let output = format_warnings(
    ["unsupported external $ref: external.json#/components/schemas/Photo"],
    WarningText,
  )
  inspect(
    output,
    content="warning: unsupported external $ref: external.json#/components/schemas/Photo\n",
  )
}

///|
test "format warnings as json lines with classified ref" {
  let output = format_warnings(
    ["unsupported external $ref: external.json#/components/schemas/Photo"],
    WarningJson,
  )
  assert_true(output.contains("\"level\":\"warning\""))
  assert_true(output.contains("\"code\":\"unsupported_external_ref\""))
  assert_true(
    output.contains("\"ref\":\"external.json#/components/schemas/Photo\""),
  )
  assert_true(output.has_suffix("\n"))
}

///|
test "format warnings supports internal ref and generic warning" {
  let internal = warning_to_json_line("unsupported internal $ref: #/x/y")
  assert_true(internal.contains("\"code\":\"unsupported_internal_ref\""))
  assert_true(internal.contains("\"ref\":\"#/x/y\""))
  let generic = warning_to_json_line("some warning")
  assert_true(generic.contains("\"code\":\"warning\""))
  assert_false(generic.contains("\"ref\""))
}

///|
test "format warnings classifies external ref resolver failures" {
  let load = warning_to_json_line(
    "external $ref load failed: photo.json#/components/schemas/Photo -- missing",
  )
  assert_true(load.contains("\"code\":\"external_ref_load_failed\""))
  assert_true(load.contains("\"ref\":\"photo.json#/components/schemas/Photo\""))
  let parse = warning_to_json_line(
    "external $ref parse failed: photo.json#/components/schemas/Photo -- bad json",
  )
  assert_true(parse.contains("\"code\":\"external_ref_parse_failed\""))
  let missing = warning_to_json_line(
    "external $ref pointer not found: photo.json#/components/schemas/Photo",
  )
  assert_true(missing.contains("\"code\":\"external_ref_pointer_not_found\""))
  let conflict = warning_to_json_line(
    "external $ref conflict: photo.json#/components/schemas/Photo -- target already exists",
  )
  assert_true(conflict.contains("\"code\":\"external_ref_conflict\""))
}

///|
test "format warnings can be suppressed" {
  assert_eq(format_warnings(["some warning"], WarningNone), "")
}

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

///|
test "format trace event as debug json line payload" {
  let output = format_trace_event("load", 7UL)
  assert_true(output.contains("\"level\":\"debug\""))
  assert_true(output.contains("\"phase\":\"load\""))
  assert_true(output.contains("\"durationMs\":7"))
}

///|
test "elapsed ms clamps backwards clocks to zero" {
  assert_eq(elapsed_ms(10UL, 15UL), 5UL)
  assert_eq(elapsed_ms(15UL, 10UL), 0UL)
}

///|
test "verbose flag is parsed on get commands" {
  let argv = ["schema", "get", "Pet", "--verbose"]
  let parsed : Result[@argparse.Matches, _] = try? command().parse(argv~)
  guard parsed is Ok(root_matches)
  guard root_matches.subcommand is Some(("schema", schema_matches))
  guard schema_matches.subcommand is Some(("get", get_matches))
  assert_true(get_matches.flags.get_or_default("verbose", false))
}

///|
test "verbose trace is disabled by default" {
  let argv = ["schema", "get", "Pet"]
  let parsed : Result[@argparse.Matches, _] = try? command().parse(argv~)
  guard parsed is Ok(root_matches)
  guard root_matches.subcommand is Some(("schema", schema_matches))
  guard schema_matches.subcommand is Some(("get", get_matches))
  let trace = new_verbose_trace(get_matches)
  assert_false(trace.enabled)
}

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
