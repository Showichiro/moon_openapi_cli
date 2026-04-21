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
fn endpoint_get_openapi() -> String {
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
    #|        "responses": {
    #|          "200": {
    #|            "description": "ok",
    #|            "content": {
    #|              "application/json": {
    #|                "schema": {
    #|                  "type": "array",
    #|                  "items": { "$ref": "#/components/schemas/Pet" }
    #|                }
    #|              }
    #|            }
    #|          }
    #|        }
    #|      },
    #|      "post": {
    #|        "operationId": "addPet",
    #|        "summary": "Add a pet",
    #|        "tags": ["pets"],
    #|        "requestBody": {
    #|          "content": {
    #|            "application/json": {
    #|              "schema": { "$ref": "#/components/schemas/NewPet" }
    #|            }
    #|          }
    #|        },
    #|        "responses": {
    #|          "201": {
    #|            "description": "created",
    #|            "content": {
    #|              "application/json": {
    #|                "schema": { "$ref": "#/components/schemas/Pet" }
    #|              }
    #|            }
    #|          }
    #|        }
    #|      }
    #|    },
    #|    "/status": {
    #|      "get": {
    #|        "operationId": "getStatus",
    #|        "tags": ["system"],
    #|        "responses": { "200": { "description": "ok" } }
    #|      }
    #|    }
    #|  },
    #|  "components": {
    #|    "schemas": {
    #|      "NewPet": {
    #|        "type": "object",
    #|        "required": ["name"],
    #|        "properties": {
    #|          "name": { "type": "string" },
    #|          "category": { "$ref": "#/components/schemas/Category" },
    #|          "photo": { "$ref": "external.json#/components/schemas/Photo" }
    #|        }
    #|      },
    #|      "Pet": {
    #|        "allOf": [
    #|          { "$ref": "#/components/schemas/NewPet" },
    #|          {
    #|            "type": "object",
    #|            "properties": {
    #|              "id": { "type": "integer" },
    #|              "related": { "$ref": "#/components/schemas/Pet" }
    #|            }
    #|          }
    #|        ]
    #|      },
    #|      "Category": {
    #|        "type": "object",
    #|        "properties": {
    #|          "name": { "type": "string" }
    #|        }
    #|      },
    #|      "Unused": { "type": "object" }
    #|    }
    #|  }
    #|}
  )
}

///|
fn missing_ref_openapi() -> String {
  (
    #|{
    #|  "openapi": "3.0.3",
    #|  "info": { "title": "Broken", "version": "1.0.0" },
    #|  "paths": {
    #|    "/broken": {
    #|      "get": {
    #|        "operationId": "broken",
    #|        "responses": {
    #|          "200": {
    #|            "description": "ok",
    #|            "content": {
    #|              "application/json": {
    #|                "schema": { "$ref": "#/components/schemas/Missing" }
    #|              }
    #|            }
    #|          }
    #|        }
    #|      }
    #|    }
    #|  },
    #|  "components": { "schemas": {} }
    #|}
  )
}

///|
fn encoded_ref_openapi() -> String {
  (
    #|{
    #|  "openapi": "3.0.3",
    #|  "info": { "title": "Encoded", "version": "1.0.0" },
    #|  "paths": {
    #|    "/encoded": {
    #|      "get": {
    #|        "operationId": "encoded",
    #|        "responses": {
    #|          "200": {
    #|            "description": "ok",
    #|            "content": {
    #|              "application/json": {
    #|                "schema": { "$ref": "#/components/schemas/Slash~1Pet" }
    #|              }
    #|            }
    #|          }
    #|        }
    #|      }
    #|    }
    #|  },
    #|  "components": {
    #|    "schemas": {
    #|      "Slash/Pet": {
    #|        "type": "object",
    #|        "properties": {
    #|          "tilde": { "$ref": "#/components/schemas/Tilde~0Pet" }
    #|        }
    #|      },
    #|      "Tilde~Pet": { "type": "object" }
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
fn get_options(no_resolve : Bool) -> EndpointGetOptions {
  endpoint_get_options(no_resolve)
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
  assert_true(result is Err(UnsupportedSpec("Swagger 2.0 is not supported")))
}

///|
test "get endpoint by operationId collects reachable components" {
  let subset = get_endpoint_from_source(
    endpoint_get_openapi(),
    "addPet",
    options=get_options(false),
  ).unwrap()
  assert_eq(subset.endpoint.operation_id, "addPet")
  assert_eq(subset.endpoint.http_method, "POST")
  assert_eq(subset.endpoint.path, "/pets")
  assert_eq(subset.warnings, [
    "unsupported external $ref: external.json#/components/schemas/Photo",
  ])
  guard subset.components is Some(Object(components))
  guard components.get("schemas") is Some(Object(schemas))
  assert_true(schemas.contains("NewPet"))
  assert_true(schemas.contains("Pet"))
  assert_true(schemas.contains("Category"))
  assert_false(schemas.contains("Unused"))
}

///|
test "get endpoint by METHOD PATH target" {
  let subset = get_endpoint_from_source(
    endpoint_get_openapi(),
    "POST /pets",
    options=get_options(true),
  ).unwrap()
  assert_eq(subset.endpoint.operation_id, "addPet")
  assert_true(subset.components is None)
  assert_eq(subset.warnings, [])
}

///|
test "get endpoint by unambiguous path" {
  let subset = get_endpoint_from_source(
    endpoint_get_openapi(),
    "/status",
    options=get_options(false),
  ).unwrap()
  assert_eq(subset.endpoint.operation_id, "getStatus")
  assert_true(subset.components is None)
}

///|
test "get endpoint rejects ambiguous path target" {
  let result = get_endpoint_from_source(
    endpoint_get_openapi(),
    "/pets",
    options=get_options(false),
  )
  assert_true(
    result is Err(AmbiguousMatch("path matched multiple methods: /pets")),
  )
}

///|
test "get endpoint rejects missing target" {
  let result = get_endpoint_from_source(
    endpoint_get_openapi(),
    "missingOperation",
    options=get_options(false),
  )
  assert_true(
    result is Err(ResourceNotFound("operation not found: missingOperation")),
  )
}

///|
test "get endpoint rejects missing internal ref" {
  let result = get_endpoint_from_source(
    missing_ref_openapi(),
    "broken",
    options=get_options(false),
  )
  assert_true(
    result is Err(ParseError("unresolved $ref: #/components/schemas/Missing")),
  )
}

///|
test "get endpoint decodes json pointer component names" {
  let subset = get_endpoint_from_source(
    encoded_ref_openapi(),
    "encoded",
    options=get_options(false),
  ).unwrap()
  guard subset.components is Some(Object(components))
  guard components.get("schemas") is Some(Object(schemas))
  assert_true(schemas.contains("Slash/Pet"))
  assert_true(schemas.contains("Tilde~Pet"))
}
