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
fn search_ranking_openapi() -> String {
  (
    #|{
    #|  "openapi": "3.0.3",
    #|  "info": { "title": "Search ranking", "version": "1.0.0" },
    #|  "paths": {
    #|    "/api/assign-career-change/v1/chat-rooms": {
    #|      "get": {
    #|        "operationId": "ChatRoomsController_findAll",
    #|        "summary": "List chat rooms",
    #|        "tags": ["chat-rooms"],
    #|        "responses": { "200": { "description": "ok" } }
    #|      }
    #|    },
    #|    "/api/assign-career-change/v1/chat-rooms/{chatRoomId}/messages": {
    #|      "get": {
    #|        "operationId": "MessagesController_findAll",
    #|        "summary": "List chat room messages",
    #|        "tags": ["messages"],
    #|        "responses": { "200": { "description": "ok" } }
    #|      }
    #|    }
    #|  }
    #|}
  )
}

///|
fn schema_search_ranking_openapi() -> String {
  (
    #|{
    #|  "openapi": "3.0.3",
    #|  "info": { "title": "Schema search ranking", "version": "1.0.0" },
    #|  "paths": {},
    #|  "components": {
    #|    "schemas": {
    #|      "CandidatePersonalInfo": {
    #|        "title": "Candidate personal info",
    #|        "type": "object"
    #|      },
    #|      "CandidateSearchCondition": {
    #|        "type": "object",
    #|        "properties": {
    #|          "candidate": { "type": "string" },
    #|          "personal": { "type": "string" },
    #|          "info": { "type": "string" }
    #|        }
    #|      }
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
fn get_options(
  no_resolve : Bool,
  inline_refs? : Bool = false,
) -> EndpointGetOptions {
  endpoint_get_options(no_resolve, inline_refs~)
}

///|
fn schema_options(with_usages : Bool) -> SchemaGetOptions {
  schema_get_options(with_usages)
}

///|
fn endpoint_search_all(limit : Int) -> EndpointSearchOptions {
  endpoint_search_options(None, None, limit)
}

///|
fn schema_search_all(limit : Int) -> SchemaSearchOptions {
  schema_search_options(limit)
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
test "search endpoints by summary and query alias" {
  let results = search_endpoints_from_source(
    endpoint_get_openapi(),
    "create pet",
    options=endpoint_search_all(10),
  ).unwrap()
  assert_true(results.length() > 0)
  assert_eq(results[0].operation_id, "addPet")
  assert_eq(results[0].target, "POST /pets")
  assert_true(results[0].score > 0)
  assert_true(results[0].matched_fields.contains("operationId"))
  assert_true(results[0].matched_fields.contains("summary"))
}

///|
test "search endpoints ranks full token coverage over partial path match" {
  let results = search_endpoints_from_source(
    search_ranking_openapi(),
    "chat room messages",
    options=endpoint_search_all(10),
  ).unwrap()
  assert_true(results.length() > 0)
  assert_eq(
    results[0].target,
    "GET /api/assign-career-change/v1/chat-rooms/{chatRoomId}/messages",
  )
}

///|
test "search endpoints respects method tag and limit" {
  let results = search_endpoints_from_source(
    sample_openapi(),
    "pets",
    options=endpoint_search_options(Some("pets"), Some("post"), 1),
  ).unwrap()
  assert_eq(results.length(), 1)
  assert_eq(results[0].operation_id, "addPet")
  assert_eq(results[0].http_method, "POST")
}

///|
test "search endpoints returns empty array for no match" {
  let results = search_endpoints_from_source(
    sample_openapi(),
    "inventory",
    options=endpoint_search_all(10),
  ).unwrap()
  assert_eq(results.length(), 0)
}

///|
test "search endpoints validates query and limit" {
  let empty = search_endpoints_from_source(
    sample_openapi(),
    "  ",
    options=endpoint_search_all(10),
  )
  assert_true(empty is Err(UsageError("expected non-empty search query")))
  let bad_limit = search_endpoints_from_source(
    sample_openapi(),
    "pets",
    options=endpoint_search_all(0),
  )
  assert_true(bad_limit is Err(UsageError("limit must be greater than 0")))
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
  guard subset.operation is Object(operation)
  guard operation.get("requestBody") is Some(Object(request_body))
  guard request_body.get("content") is Some(Object(request_content))
  guard request_content.get("application/json") is Some(Object(request_media))
  guard request_media.get("schema") is Some(Object(request_schema))
  assert_eq(
    request_schema.get("$ref"),
    Some(Json::string("#/components/schemas/NewPet")),
  )
  guard subset.components is Some(Object(components))
  guard components.get("schemas") is Some(Object(schemas))
  assert_true(schemas.contains("NewPet"))
  assert_true(schemas.contains("Pet"))
  assert_true(schemas.contains("Category"))
  assert_false(schemas.contains("Unused"))
}

///|
test "get endpoint inline refs expands operation and components" {
  let subset = get_endpoint_from_source(
    endpoint_get_openapi(),
    "addPet",
    options=get_options(false, inline_refs=true),
  ).unwrap()
  assert_eq(subset.warnings, [
    "unsupported external $ref: external.json#/components/schemas/Photo",
  ])
  guard subset.operation is Object(operation)
  guard operation.get("requestBody") is Some(Object(request_body))
  guard request_body.get("content") is Some(Object(request_content))
  guard request_content.get("application/json") is Some(Object(request_media))
  guard request_media.get("schema") is Some(Object(request_schema))
  assert_false(request_schema.contains("$ref"))
  assert_eq(request_schema.get("title"), Some(Json::string("New pet")))
  guard request_schema.get("properties") is Some(Object(request_props))
  guard request_props.get("category") is Some(Object(request_category))
  assert_false(request_category.contains("$ref"))
  assert_eq(request_category.get("title"), Some(Json::string("Category")))
  guard request_props.get("photo") is Some(Object(request_photo))
  assert_eq(
    request_photo.get("$ref"),
    Some(Json::string("external.json#/components/schemas/Photo")),
  )
  guard operation.get("responses") is Some(Object(responses))
  guard responses.get("201") is Some(Object(created_response))
  guard created_response.get("content") is Some(Object(response_content))
  guard response_content.get("application/json") is Some(Object(response_media))
  guard response_media.get("schema") is Some(Object(response_schema))
  assert_false(response_schema.contains("$ref"))
  assert_eq(response_schema.get("title"), Some(Json::string("Pet")))
  guard response_schema.get("allOf") is Some(Array(all_of))
  guard all_of[0] is Object(inline_new_pet)
  assert_eq(inline_new_pet.get("title"), Some(Json::string("New pet")))
  guard all_of[1] is Object(pet_extension)
  guard pet_extension.get("properties") is Some(Object(pet_props))
  guard pet_props.get("related") is Some(Object(related_pet))
  assert_eq(
    related_pet.get("$ref"),
    Some(Json::string("#/components/schemas/Pet")),
  )
  guard subset.components is Some(Object(components))
  guard components.get("schemas") is Some(Object(schemas))
  guard schemas.get("NewPet") is Some(Object(component_new_pet))
  guard component_new_pet.get("properties") is Some(Object(component_props))
  guard component_props.get("category") is Some(Object(component_category))
  assert_eq(component_category.get("title"), Some(Json::string("Category")))
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
test "get endpoint no-resolve takes precedence over inline refs" {
  let subset = get_endpoint_from_source(
    endpoint_get_openapi(),
    "POST /pets",
    options=get_options(true, inline_refs=true),
  ).unwrap()
  assert_true(subset.components is None)
  assert_eq(subset.warnings, [])
  guard subset.operation is Object(operation)
  guard operation.get("requestBody") is Some(Object(request_body))
  guard request_body.get("content") is Some(Object(request_content))
  guard request_content.get("application/json") is Some(Object(request_media))
  guard request_media.get("schema") is Some(Object(request_schema))
  assert_eq(
    request_schema.get("$ref"),
    Some(Json::string("#/components/schemas/NewPet")),
  )
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
test "search schemas by title and property name" {
  let results = search_schemas_from_source(
    endpoint_get_openapi(),
    "category name",
    options=schema_search_all(10),
  ).unwrap()
  assert_true(results.length() > 0)
  assert_eq(results[0].name, "Category")
  assert_true(results[0].matched_fields.contains("name"))
  assert_true(results[0].matched_fields.contains("properties"))
}

///|
test "search schemas prefers schema identity over property-only matches" {
  let results = search_schemas_from_source(
    schema_search_ranking_openapi(),
    "candidate personal info",
    options=schema_search_all(10),
  ).unwrap()
  assert_true(results.length() > 1)
  assert_eq(results[0].name, "CandidatePersonalInfo")
  assert_true(results[0].matched_fields.contains("name"))
}

///|
test "search schemas respects limit" {
  let results = search_schemas_from_source(
    endpoint_get_openapi(),
    "pet",
    options=schema_search_all(1),
  ).unwrap()
  assert_eq(results.length(), 1)
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
