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
      @moon_openapi_cli.JsonLines,
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
      @moon_openapi_cli.Markdown,
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
    @moon_openapi_cli.format_endpoint_list(endpoints, @moon_openapi_cli.Quiet),
    content=(
      #|listPets
      #|addPet
    ),
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
      @moon_openapi_cli.EndpointGetJson,
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
    @moon_openapi_cli.EndpointGetMarkdown,
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
