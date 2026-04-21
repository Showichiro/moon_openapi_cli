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
