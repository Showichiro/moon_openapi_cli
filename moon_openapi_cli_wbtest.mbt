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
    #|        "title": "New pet",
    #|        "type": "object",
    #|        "required": ["name"],
    #|        "properties": {
    #|          "name": { "type": "string" },
    #|          "category": { "$ref": "#/components/schemas/Category" },
    #|          "photo": { "$ref": "external.json#/components/schemas/Photo" }
    #|        }
    #|      },
    #|      "Pet": {
    #|        "title": "Pet",
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
    #|        "title": "Category",
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
fn swagger2_openapi() -> String {
  (
    #|{
    #|  "swagger": "2.0",
    #|  "info": { "title": "Petstore", "version": "1.0.0" },
    #|  "consumes": ["application/json"],
    #|  "produces": ["application/json"],
    #|  "paths": {
    #|    "/pets": {
    #|      "get": {
    #|        "operationId": "listPets",
    #|        "summary": "List pets",
    #|        "tags": ["pets"],
    #|        "responses": {
    #|          "200": {
    #|            "description": "ok",
    #|            "schema": {
    #|              "type": "array",
    #|              "items": { "$ref": "#/definitions/Pet" }
    #|            }
    #|          }
    #|        }
    #|      },
    #|      "post": {
    #|        "operationId": "addPet",
    #|        "summary": "Add a pet",
    #|        "tags": ["pets"],
    #|        "parameters": [
    #|          {
    #|            "name": "body",
    #|            "in": "body",
    #|            "required": true,
    #|            "schema": { "$ref": "#/definitions/NewPet" }
    #|          },
    #|          {
    #|            "name": "traceId",
    #|            "in": "header",
    #|            "type": "string"
    #|          }
    #|        ],
    #|        "responses": {
    #|          "201": {
    #|            "description": "created",
    #|            "schema": { "$ref": "#/definitions/Pet" }
    #|          }
    #|        }
    #|      }
    #|    }
    #|  },
    #|  "definitions": {
    #|    "NewPet": {
    #|      "title": "New pet",
    #|      "type": "object",
    #|      "required": ["name"],
    #|      "properties": {
    #|        "name": { "type": "string" },
    #|        "category": { "$ref": "#/definitions/Category" }
    #|      }
    #|    },
    #|    "Pet": {
    #|      "title": "Pet",
    #|      "allOf": [
    #|        { "$ref": "#/definitions/NewPet" },
    #|        {
    #|          "type": "object",
    #|          "properties": {
    #|            "id": { "type": "integer" }
    #|          }
    #|        }
    #|      ]
    #|    },
    #|    "Category": {
    #|      "title": "Category",
    #|      "type": "object",
    #|      "properties": {
    #|        "name": { "type": "string" }
    #|      }
    #|    }
    #|  }
    #|}
  )
}

///|
fn duplicate_body_swagger2_openapi() -> String {
  (
    #|{
    #|  "swagger": "2.0",
    #|  "info": { "title": "Broken", "version": "1.0.0" },
    #|  "paths": {
    #|    "/broken": {
    #|      "post": {
    #|        "operationId": "broken",
    #|        "parameters": [
    #|          { "name": "a", "in": "body", "schema": { "type": "object" } },
    #|          { "name": "b", "in": "body", "schema": { "type": "object" } }
    #|        ],
    #|        "responses": { "200": { "description": "ok" } }
    #|      }
    #|    }
    #|  }
    #|}
  )
}

///|
fn openapi31_openapi() -> String {
  (
    #|{
    #|  "openapi": "3.1.0",
    #|  "info": { "title": "Petstore 3.1", "version": "1.0.0" },
    #|  "paths": {
    #|    "/pets": {
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
    #|    }
    #|  },
    #|  "components": {
    #|    "schemas": {
    #|      "NewPet": {
    #|        "type": "object",
    #|        "properties": {
    #|          "name": { "type": "string" }
    #|        }
    #|      },
    #|      "Pet": {
    #|        "allOf": [
    #|          { "$ref": "#/components/schemas/NewPet" },
    #|          { "type": "object" }
    #|        ]
    #|      }
    #|    }
    #|  }
    #|}
  )
}

///|
fn no_components_openapi() -> String {
  (
    #|{
    #|  "openapi": "3.0.3",
    #|  "info": { "title": "No components", "version": "1.0.0" },
    #|  "paths": {}
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
fn schema_options(with_usages : Bool) -> SchemaGetOptions {
  schema_get_options(with_usages)
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
test "accept swagger 2 source when listing endpoints" {
  let result = list_endpoints_from_source(
    swagger2_openapi(),
    options=all_options(),
  )
  assert_eq(result.unwrap().map(endpoint => endpoint.operation_id), [
    "listPets", "addPet",
  ])
}

///|
test "reject unsupported swagger source" {
  let result = list_endpoints_from_source(
    (
      #|{
      #|  "swagger": "1.2",
      #|  "paths": {}
      #|}
    ),
    options=all_options(),
  )
  assert_true(
    result is Err(UnsupportedSpec("unsupported Swagger version: 1.2")),
  )
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

///|
test "list schemas from components schemas" {
  let schemas = list_schemas_from_source(endpoint_get_openapi()).unwrap()
  assert_eq(schemas.map(schema => schema.name), [
    "Category", "NewPet", "Pet", "Unused",
  ])
  assert_eq(schemas[1].title, Some("New pet"))
  assert_eq(schemas[1].schema_type, Some("object"))
  assert_eq(schemas[2].title, Some("Pet"))
  assert_true(schemas[2].schema_type is None)
}

///|
test "list schemas treats missing components as empty" {
  let schemas = list_schemas_from_source(no_components_openapi()).unwrap()
  assert_eq(schemas.length(), 0)
}

///|
test "get schema includes reachable schema components" {
  let subset = get_schema_from_source(
    endpoint_get_openapi(),
    "Pet",
    options=schema_options(false),
  ).unwrap()
  assert_eq(subset.name, "Pet")
  assert_true(subset.usages is None)
  assert_eq(subset.warnings, [
    "unsupported external $ref: external.json#/components/schemas/Photo",
  ])
  guard subset.components is Some(Object(components))
  guard components.get("schemas") is Some(Object(schemas))
  assert_true(schemas.contains("Pet"))
  assert_true(schemas.contains("NewPet"))
  assert_true(schemas.contains("Category"))
  assert_false(schemas.contains("Unused"))
}

///|
test "get schema with usages finds transitive operation usages" {
  let subset = get_schema_from_source(
    endpoint_get_openapi(),
    "Category",
    options=schema_options(true),
  ).unwrap()
  guard subset.usages is Some(usages)
  assert_eq(usages.map(usage => usage.operation_id), ["listPets", "addPet"])
  assert_eq(subset.warnings, [
    "unsupported external $ref: external.json#/components/schemas/Photo",
  ])
}

///|
test "get schema rejects missing schema" {
  let result = get_schema_from_source(
    endpoint_get_openapi(),
    "Missing",
    options=schema_options(false),
  )
  assert_true(result is Err(ResourceNotFound("schema not found: Missing")))
}

///|
test "get schema decodes json pointer component names" {
  let subset = get_schema_from_source(
    encoded_ref_openapi(),
    "Slash/Pet",
    options=schema_options(false),
  ).unwrap()
  guard subset.components is Some(Object(components))
  guard components.get("schemas") is Some(Object(schemas))
  assert_true(schemas.contains("Slash/Pet"))
  assert_true(schemas.contains("Tilde~Pet"))
}

///|
test "get endpoint normalizes swagger 2 body and response schemas" {
  let subset = get_endpoint_from_source(
    swagger2_openapi(),
    "addPet",
    options=get_options(false),
  ).unwrap()
  assert_eq(subset.openapi_version, "3.0.0")
  guard subset.operation is Object(operation)
  guard operation.get("requestBody") is Some(Object(request_body))
  guard request_body.get("content") is Some(Object(request_content))
  guard request_content.get("application/json") is Some(Object(request_media))
  guard request_media.get("schema") is Some(Object(request_schema))
  assert_eq(
    request_schema.get("$ref"),
    Some(Json::string("#/components/schemas/NewPet")),
  )
  guard operation.get("responses") is Some(Object(responses))
  guard responses.get("201") is Some(Object(created_response))
  guard created_response.get("content") is Some(Object(response_content))
  guard response_content.get("application/json") is Some(Object(response_media))
  guard response_media.get("schema") is Some(Object(response_schema))
  assert_eq(
    response_schema.get("$ref"),
    Some(Json::string("#/components/schemas/Pet")),
  )
  guard subset.components is Some(Object(components))
  guard components.get("schemas") is Some(Object(schemas))
  assert_true(schemas.contains("Pet"))
  assert_true(schemas.contains("NewPet"))
  assert_true(schemas.contains("Category"))
}

///|
test "get schema works with swagger 2 definitions" {
  let subset = get_schema_from_source(
    swagger2_openapi(),
    "Pet",
    options=schema_options(true),
  ).unwrap()
  assert_eq(subset.openapi_version, "3.0.0")
  guard subset.usages is Some(usages)
  assert_eq(usages.map(usage => usage.operation_id), ["listPets", "addPet"])
  guard subset.components is Some(Object(components))
  guard components.get("schemas") is Some(Object(schemas))
  assert_true(schemas.contains("Pet"))
  assert_true(schemas.contains("NewPet"))
  assert_true(schemas.contains("Category"))
}

///|
test "reject swagger 2 operations with duplicate body parameters" {
  let result = get_endpoint_from_source(
    duplicate_body_swagger2_openapi(),
    "broken",
    options=get_options(false),
  )
  assert_true(
    result is Err(ParseError("multiple body parameters are not supported")),
  )
}

///|
test "accept openapi 3.1 endpoint and schema lookups" {
  let endpoint = get_endpoint_from_source(
    openapi31_openapi(),
    "addPet",
    options=get_options(false),
  ).unwrap()
  assert_eq(endpoint.openapi_version, "3.1.0")
  guard endpoint.components is Some(Object(endpoint_components))
  guard endpoint_components.get("schemas") is Some(Object(endpoint_schemas))
  assert_true(endpoint_schemas.contains("Pet"))
  let schema = get_schema_from_source(
    openapi31_openapi(),
    "Pet",
    options=schema_options(false),
  ).unwrap()
  assert_eq(schema.openapi_version, "3.1.0")
  guard schema.components is Some(Object(schema_components))
  guard schema_components.get("schemas") is Some(Object(schema_schemas))
  assert_true(schema_schemas.contains("Pet"))
  assert_true(schema_schemas.contains("NewPet"))
}

///|
test "reject unsupported openapi major version" {
  let result = list_endpoints_from_source(
    (
      #|{
      #|  "openapi": "4.0.0",
      #|  "paths": {}
      #|}
    ),
    options=all_options(),
  )
  assert_true(
    result is Err(UnsupportedSpec("unsupported OpenAPI version: 4.0.0")),
  )
}
