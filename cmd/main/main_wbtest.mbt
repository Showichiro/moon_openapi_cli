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
    is Err(@lib.UsageError("unsupported warnings: yaml")),
  )
}
