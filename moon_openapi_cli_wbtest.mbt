///|
fn sample_openapi() -> String {
  (
    #|{
    #|  "openapi": "3.0.3",
    #|  "info": { "title": "Petstore", "version": "1.0.0" },
    #|  "paths": {
    #|    "/pets": {
    #|      "get": {
    #|        "operationId": "listPets",
    #|        "summary": "List pets",
    #|        "tags": ["pets"],
    #|        "responses": { "200": { "description": "ok" } }
    #|      },
    #|      "post": {
    #|        "operationId": "addPet",
    #|        "tags": ["pets"],
    #|        "responses": { "201": { "description": "created" } }
    #|      },
    #|      "parameters": []
    #|    },
    #|    "/users": {
    #|      "get": {
    #|        "operationId": "listUsers",
    #|        "tags": ["users"],
    #|        "responses": { "200": { "description": "ok" } }
    #|      }
    #|    },
    #|    "/status": {
    #|      "get": {
    #|        "tags": ["system"],
    #|        "responses": { "200": { "description": "ok" } }
    #|      }
    #|    }
    #|  },
    #|  "components": {
    #|    "schemas": {
    #|      "Pet": { "type": "object" }
    #|    }
    #|  }
    #|}
  )
}

///|
fn all_options() -> EndpointListOptions {
  endpoint_list_options(None, None)
}

///|
test "list endpoints from OpenAPI 3 source" {
  let endpoints = list_endpoints_from_source(
    sample_openapi(),
    options=all_options(),
  ).unwrap()
  assert_eq(endpoints.length(), 4)
  assert_eq(endpoints[0].operation_id, "listPets")
  assert_eq(endpoints[0].http_method, "GET")
  assert_eq(endpoints[0].path, "/pets")
  assert_eq(endpoints[1].operation_id, "addPet")
  assert_eq(endpoints[2].operation_id, "GET /status")
  assert_eq(endpoints[3].operation_id, "listUsers")
}

///|
test "filter endpoints by tag" {
  let endpoints = list_endpoints_from_source(
    sample_openapi(),
    options=endpoint_list_options(Some("pets"), None),
  ).unwrap()
  assert_eq(endpoints.map(endpoint => endpoint.operation_id), [
    "listPets", "addPet",
  ])
}

///|
test "filter endpoints by method ignoring case" {
  let endpoints = list_endpoints_from_source(
    sample_openapi(),
    options=endpoint_list_options(None, Some("post")),
  ).unwrap()
  assert_eq(endpoints.map(endpoint => endpoint.operation_id), ["addPet"])
}

///|
test "reject non object input before json parse" {
  let result = list_endpoints_from_source("[]", options=all_options())
  assert_true(result is Err(ParseError("expected JSON object input")))
}

///|
test "reject unsupported swagger source in M1" {
  let result = list_endpoints_from_source(
    (
      #|{
      #|  "swagger": "2.0",
      #|  "paths": {}
      #|}
    ),
    options=all_options(),
  )
  assert_true(
    result is Err(UnsupportedSpec("Swagger 2.0 is not supported in M1")),
  )
}
