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
