///|
test "format endpoint list as json lines" {
  let endpoints : Array[@moon_openapi_cli.EndpointSummary] = [
    {
      operation_id: "listPets",
      http_method: "GET",
      path: "/pets",
      tags: ["pets"],
      summary: Some("List pets"),
    },
  ]
  inspect(
    @moon_openapi_cli.format_endpoint_list(
      endpoints,
      @moon_openapi_cli.EndpointListFormat::JsonLines,
    ),
    content=(
      #|{"operationId":"listPets","method":"GET","path":"/pets","tags":["pets"],"summary":"List pets"}
    ),
  )
}

///|
test "format endpoint list as markdown" {
  let endpoints : Array[@moon_openapi_cli.EndpointSummary] = [
    {
      operation_id: "addPet",
      http_method: "POST",
      path: "/pets",
      tags: ["pets"],
      summary: None,
    },
  ]
  inspect(
    @moon_openapi_cli.format_endpoint_list(
      endpoints,
      @moon_openapi_cli.EndpointListFormat::Markdown,
    ),
    content="- POST /pets addPet",
  )
}

///|
test "format endpoint list as quiet ids" {
  let endpoints : Array[@moon_openapi_cli.EndpointSummary] = [
    {
      operation_id: "listPets",
      http_method: "GET",
      path: "/pets",
      tags: ["pets"],
      summary: None,
    },
    {
      operation_id: "addPet",
      http_method: "POST",
      path: "/pets",
      tags: ["pets"],
      summary: None,
    },
  ]
  inspect(
    @moon_openapi_cli.format_endpoint_list(
      endpoints,
      @moon_openapi_cli.EndpointListFormat::Quiet,
    ),
    content=(
      #|listPets
      #|addPet
    ),
  )
}

///|
test "format endpoint search results" {
  let results : Array[@moon_openapi_cli.EndpointSearchResult] = [
    {
      operation_id: "addPet",
      target: "POST /pets",
      http_method: "POST",
      path: "/pets",
      tags: ["pets"],
      summary: Some("Add a pet"),
      score: 120,
      matched_fields: ["operationId", "summary"],
    },
  ]
  let json = @moon_openapi_cli.format_endpoint_search_results(
    results,
    @moon_openapi_cli.EndpointSearchFormat::EndpointSearchJsonLines,
  )
  assert_true(json.contains("\"operationId\":\"addPet\""))
  assert_true(json.contains("\"target\":\"POST /pets\""))
  assert_true(json.contains("\"score\":120"))
  assert_true(json.contains("\"matchedFields\""))
  inspect(
    @moon_openapi_cli.format_endpoint_search_results(
      results,
      @moon_openapi_cli.EndpointSearchFormat::EndpointSearchQuiet,
    ),
    content="POST /pets",
  )
}

///|
fn empty_json_object() -> Json {
  let object : Map[String, Json] = {}
  Json::object(object)
}

///|
test "format endpoint subset as json" {
  let subset : @moon_openapi_cli.EndpointSubset = {
    openapi_version: "3.0.3",
    endpoint: {
      operation_id: "addPet",
      http_method: "POST",
      path: "/pets",
      tags: ["pets"],
      summary: Some("Add a pet"),
    },
    operation: {
      "operationId": Json::string("addPet"),
      "responses": Json::object({ "201": empty_json_object() }),
    },
    components: None,
    warnings: [],
  }
  inspect(
    @moon_openapi_cli.format_endpoint_subset(
      subset,
      @moon_openapi_cli.EndpointGetFormat::EndpointGetJson,
    ),
    content=(
      #|{
      #|  "openapi": "3.0.3",
      #|  "paths": {
      #|    "/pets": {
      #|      "post": {
      #|        "operationId": "addPet",
      #|        "responses": {
      #|          "201": {}
      #|        }
      #|      }
      #|    }
      #|  }
      #|}
    ),
  )
}

///|
test "format endpoint subset as markdown" {
  let subset : @moon_openapi_cli.EndpointSubset = {
    openapi_version: "3.0.3",
    endpoint: {
      operation_id: "addPet",
      http_method: "POST",
      path: "/pets",
      tags: ["pets"],
      summary: Some("Add a pet"),
    },
    operation: {
      "operationId": Json::string("addPet"),
      "responses": Json::object({ "201": empty_json_object() }),
    },
    components: Some(Json::object({ "schemas": empty_json_object() })),
    warnings: [],
  }
  let markdown = @moon_openapi_cli.format_endpoint_subset(
    subset,
    @moon_openapi_cli.EndpointGetFormat::EndpointGetMarkdown,
  )
  assert_true(markdown.contains("## POST /pets"))
  assert_true(markdown.contains("operationId: addPet"))
  assert_true(markdown.contains("### Responses"))
  assert_true(markdown.contains("### Components"))
}

///|
test "format schema list as json lines" {
  let schemas : Array[@moon_openapi_cli.SchemaSummary] = [
    { name: "Pet", title: Some("Pet"), schema_type: Some("object") },
  ]
  inspect(
    @moon_openapi_cli.format_schema_list(
      schemas,
      @moon_openapi_cli.SchemaListJsonLines,
    ),
    content="{\"name\":\"Pet\",\"title\":\"Pet\",\"type\":\"object\"}",
  )
}

///|
test "format schema list as markdown" {
  let schemas : Array[@moon_openapi_cli.SchemaSummary] = [
    { name: "Pet", title: Some("Pet"), schema_type: Some("object") },
    { name: "Category", title: None, schema_type: None },
  ]
  inspect(
    @moon_openapi_cli.format_schema_list(
      schemas,
      @moon_openapi_cli.SchemaListMarkdown,
    ),
    content=(
      #|- Pet (object) - Pet
      #|- Category
    ),
  )
}

///|
test "format schema list as quiet names" {
  let schemas : Array[@moon_openapi_cli.SchemaSummary] = [
    { name: "Pet", title: None, schema_type: None },
    { name: "Category", title: None, schema_type: None },
  ]
  inspect(
    @moon_openapi_cli.format_schema_list(
      schemas,
      @moon_openapi_cli.SchemaListQuiet,
    ),
    content=(
      #|Pet
      #|Category
    ),
  )
}

///|
test "format schema search results" {
  let results : Array[@moon_openapi_cli.SchemaSearchResult] = [
    {
      name: "Pet",
      title: Some("Pet"),
      schema_type: Some("object"),
      score: 80,
      matched_fields: ["name"],
    },
  ]
  let markdown = @moon_openapi_cli.format_schema_search_results(
    results,
    @moon_openapi_cli.SchemaSearchMarkdown,
  )
  assert_true(markdown.contains("- Pet (object, score: 80) - Pet"))
  inspect(
    @moon_openapi_cli.format_schema_search_results(
      results,
      @moon_openapi_cli.SchemaSearchQuiet,
    ),
    content="Pet",
  )
}

///|
test "format schema subset as json" {
  let subset : @moon_openapi_cli.SchemaSubset = {
    openapi_version: "3.0.3",
    name: "Pet",
    schema: Json::object({ "type": Json::string("object") }),
    components: Some(Json::object({ "schemas": empty_json_object() })),
    usages: Some([
      {
        operation_id: "listPets",
        http_method: "GET",
        path: "/pets",
        tags: ["pets"],
        summary: None,
      },
    ]),
    warnings: [],
  }
  let output = @moon_openapi_cli.format_schema_subset(
    subset,
    @moon_openapi_cli.SchemaGetJson,
  )
  assert_true(output.contains("\"openapi\": \"3.0.3\""))
  assert_true(output.contains("\"components\""))
  assert_true(output.contains("\"usages\""))
  assert_true(output.contains("\"operationId\": \"listPets\""))
}

///|
test "format schema subset as markdown" {
  let subset : @moon_openapi_cli.SchemaSubset = {
    openapi_version: "3.0.3",
    name: "Pet",
    schema: Json::object({ "type": Json::string("object") }),
    components: Some(Json::object({ "schemas": empty_json_object() })),
    usages: Some([]),
    warnings: [],
  }
  let markdown = @moon_openapi_cli.format_schema_subset(
    subset,
    @moon_openapi_cli.SchemaGetMarkdown,
  )
  assert_true(markdown.contains("## Pet"))
  assert_true(markdown.contains("### Schema"))
  assert_true(markdown.contains("### Components"))
  assert_true(markdown.contains("### Usages"))
  assert_true(markdown.contains("- none"))
}

///|
test "describe command metadata includes schemas" {
  assert_eq(@moon_openapi_cli.describe_command_names(), [
    "endpoint.ls", "endpoint.get", "endpoint.search", "schema.ls", "schema.get",
    "schema.search", "describe", "version",
  ])
  let result = @moon_openapi_cli.describe_command("endpoint.get")
  guard result is Ok(descriptor)
  assert_eq(descriptor.name, "endpoint.get")
  let json = descriptor.to_json().stringify()
  assert_true(json.contains("\"inputSchema\""))
  assert_true(json.contains("\"target\""))
  assert_true(json.contains("\"noResolve\""))
  assert_true(json.contains("\"warnings\""))
  assert_true(json.contains("\"verbose\""))
  assert_true(json.contains("\"none\""))
  assert_true(json.contains("\"outputSchema\""))
}

///|
test "describe search metadata includes limit and query" {
  let result = @moon_openapi_cli.describe_command("endpoint.search")
  guard result is Ok(descriptor)
  let json = descriptor.to_json().stringify()
  assert_true(json.contains("\"query\""))
  assert_true(json.contains("\"limit\""))
  assert_true(json.contains("\"matchedFields\""))
  assert_true(json.contains("\"score\""))
}

///|
test "describe schema get metadata includes warnings option" {
  let result = @moon_openapi_cli.describe_command("schema.get")
  guard result is Ok(descriptor)
  let json = descriptor.to_json().stringify()
  assert_true(json.contains("\"warnings\""))
  assert_true(json.contains("\"json\""))
  assert_true(json.contains("\"withUsages\""))
  assert_true(json.contains("\"verbose\""))
}

///|
test "describe list metadata includes verbose option" {
  let result = @moon_openapi_cli.describe_command("endpoint.ls")
  guard result is Ok(descriptor)
  let json = descriptor.to_json().stringify()
  assert_true(json.contains("\"quiet\""))
  assert_true(json.contains("\"verbose\""))
}

///|
test "format command descriptors as json array" {
  let output = @moon_openapi_cli.format_command_descriptors(
    @moon_openapi_cli.describe_commands(),
  )
  assert_true(output.contains("\"name\": \"endpoint.ls\""))
  assert_true(output.contains("\"name\": \"endpoint.search\""))
  assert_true(output.contains("\"name\": \"schema.get\""))
  assert_true(output.contains("\"inputSchema\""))
  assert_true(output.contains("\"outputSchema\""))
}

///|
test "describe command rejects unknown descriptor" {
  let result = @moon_openapi_cli.describe_command("missing")
  guard result is Err(err)
  assert_eq(err.exit_code(), 3)
  assert_true(
    err.to_stderr_json().contains("command descriptor not found: missing"),
  )
}

///|
test "error json can include input and suggestion" {
  inspect(
    @moon_openapi_cli.ApispecError::UsageError("bad input").to_stderr_json(),
    content="{\"error\":\"usage_error\",\"message\":\"bad input\"}",
  )
  let output = @moon_openapi_cli.ApispecError::UsageError(
    "unsupported format: yaml",
  ).to_stderr_json_with_context(
    Some("yaml"),
    Some("supported formats: json, md"),
  )
  assert_true(output.contains("\"input\":\"yaml\""))
  assert_true(output.contains("\"suggestion\":\"supported formats: json, md\""))
}
