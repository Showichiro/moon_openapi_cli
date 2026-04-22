///|
fn command_descriptor_schema() -> Json {
  object_schema(
    {
      "name": string_schema("Descriptor name."),
      "description": string_schema("Human-readable command summary."),
      "inputSchema": json_schema("JSON Schema for command inputs."),
      "outputSchema": json_schema("JSON Schema for command outputs."),
    },
    ["name", "description", "inputSchema", "outputSchema"],
  )
}

///|
fn endpoint_summary_schema() -> Json {
  object_schema(
    {
      "operationId": string_schema(
        "OpenAPI operationId or generated METHOD PATH id.",
      ),
      "method": string_schema("HTTP method."),
      "path": string_schema("OpenAPI path template."),
      "tags": array_schema(string_schema("Operation tag.")),
      "summary": string_schema("Optional operation summary."),
    },
    ["operationId", "method", "path", "tags"],
  )
}

///|
fn endpoint_subset_schema() -> Json {
  object_schema(
    {
      "openapi": string_schema("Normalized OpenAPI version."),
      "paths": json_schema("Single-operation OpenAPI paths object."),
      "components": json_schema("Reachable OpenAPI components."),
    },
    ["openapi", "paths"],
  )
}

///|
fn endpoint_search_result_schema() -> Json {
  object_schema(
    {
      "operationId": string_schema(
        "OpenAPI operationId or generated METHOD PATH id.",
      ),
      "target": string_schema(
        "Stable endpoint target accepted by endpoint get.",
      ),
      "method": string_schema("HTTP method."),
      "path": string_schema("OpenAPI path template."),
      "tags": array_schema(string_schema("Operation tag.")),
      "summary": string_schema("Optional operation summary."),
      "score": integer_schema("Search relevance score."),
      "matchedFields": array_schema(string_schema("Matched search field.")),
    },
    [
      "operationId", "target", "method", "path", "tags", "score", "matchedFields",
    ],
  )
}

///|
fn schema_summary_schema() -> Json {
  object_schema(
    {
      "name": string_schema("Schema name."),
      "title": string_schema("Optional schema title."),
      "type": string_schema("Optional JSON Schema type."),
    },
    ["name"],
  )
}

///|
fn schema_search_result_schema() -> Json {
  object_schema(
    {
      "name": string_schema("Schema name."),
      "title": string_schema("Optional schema title."),
      "type": string_schema("Optional JSON Schema type."),
      "score": integer_schema("Search relevance score."),
      "matchedFields": array_schema(string_schema("Matched search field.")),
    },
    ["name", "score", "matchedFields"],
  )
}

///|
fn schema_subset_schema() -> Json {
  object_schema(
    {
      "openapi": string_schema("Normalized OpenAPI version."),
      "components": json_schema("Reachable OpenAPI components."),
      "usages": array_schema(endpoint_summary_schema()),
    },
    ["openapi"],
  )
}
