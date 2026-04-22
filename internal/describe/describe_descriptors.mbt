///|
fn endpoint_ls_descriptor() -> CommandDescriptor {
  {
    name: "endpoint.ls",
    description: "List OpenAPI operations from an input document.",
    input_schema: object_schema(
      {
        "file": string_schema(
          "Input JSON file path, http(s) URL, or '-' for stdin.",
        ),
        "tag": string_schema("Filter operations by tag."),
        "method": string_schema("Filter operations by HTTP method."),
        "format": enum_schema("Output format.", ["json", "md"]),
        "quiet": boolean_schema("Emit operationIds only."),
        "verbose": boolean_schema("Emit phase timing JSON Lines on stderr."),
      },
      [],
    ),
    output_schema: array_schema(endpoint_summary_schema()),
  }
}

///|
fn endpoint_get_descriptor() -> CommandDescriptor {
  {
    name: "endpoint.get",
    description: "Extract one OpenAPI operation with reachable component definitions.",
    input_schema: object_schema(
      {
        "target": string_schema("operationId, METHOD PATH, or PATH."),
        "file": string_schema(
          "Input JSON file path, http(s) URL, or '-' for stdin.",
        ),
        "format": enum_schema("Output format.", ["json", "md"]),
        "warnings": enum_schema("Warning output format.", [
          "text", "json", "none",
        ]),
        "noResolve": boolean_schema(
          "Skip reachable component inclusion and external ref import.",
        ),
        "verbose": boolean_schema("Emit phase timing JSON Lines on stderr."),
      },
      ["target"],
    ),
    output_schema: endpoint_subset_schema(),
  }
}

///|
fn endpoint_search_descriptor() -> CommandDescriptor {
  {
    name: "endpoint.search",
    description: "Search OpenAPI operations by operationId, path, summary, method, or tag.",
    input_schema: object_schema(
      {
        "query": string_schema("Search query."),
        "file": string_schema(
          "Input JSON file path, http(s) URL, or '-' for stdin.",
        ),
        "tag": string_schema("Filter operations by tag."),
        "method": string_schema("Filter operations by HTTP method."),
        "limit": integer_schema("Maximum number of results."),
        "format": enum_schema("Output format.", ["json", "md"]),
        "quiet": boolean_schema("Emit METHOD PATH targets only."),
        "verbose": boolean_schema("Emit phase timing JSON Lines on stderr."),
      },
      ["query"],
    ),
    output_schema: array_schema(endpoint_search_result_schema()),
  }
}

///|
fn schema_ls_descriptor() -> CommandDescriptor {
  {
    name: "schema.ls",
    description: "List OpenAPI component schemas from an input document.",
    input_schema: object_schema(
      {
        "file": string_schema(
          "Input JSON file path, http(s) URL, or '-' for stdin.",
        ),
        "format": enum_schema("Output format.", ["json", "md"]),
        "quiet": boolean_schema("Emit schema names only."),
        "verbose": boolean_schema("Emit phase timing JSON Lines on stderr."),
      },
      [],
    ),
    output_schema: array_schema(schema_summary_schema()),
  }
}

///|
fn schema_get_descriptor() -> CommandDescriptor {
  {
    name: "schema.get",
    description: "Extract one OpenAPI component schema with reachable components.",
    input_schema: object_schema(
      {
        "name": string_schema("Schema name under components.schemas."),
        "file": string_schema(
          "Input JSON file path, http(s) URL, or '-' for stdin.",
        ),
        "format": enum_schema("Output format.", ["json", "md"]),
        "warnings": enum_schema("Warning output format.", [
          "text", "json", "none",
        ]),
        "withUsages": boolean_schema(
          "Include operations that reference the schema.",
        ),
        "verbose": boolean_schema("Emit phase timing JSON Lines on stderr."),
      },
      ["name"],
    ),
    output_schema: schema_subset_schema(),
  }
}

///|
fn schema_search_descriptor() -> CommandDescriptor {
  {
    name: "schema.search",
    description: "Search OpenAPI component schemas by name, title, type, description, or property.",
    input_schema: object_schema(
      {
        "query": string_schema("Search query."),
        "file": string_schema(
          "Input JSON file path, http(s) URL, or '-' for stdin.",
        ),
        "limit": integer_schema("Maximum number of results."),
        "format": enum_schema("Output format.", ["json", "md"]),
        "quiet": boolean_schema("Emit schema names only."),
        "verbose": boolean_schema("Emit phase timing JSON Lines on stderr."),
      },
      ["query"],
    ),
    output_schema: array_schema(schema_search_result_schema()),
  }
}

///|
fn describe_descriptor() -> CommandDescriptor {
  {
    name: "describe",
    description: "Describe available apispec commands as MCP-compatible metadata.",
    input_schema: object_schema(
      {
        "subcommand": enum_schema("Optional descriptor name to return.", [
          "endpoint.ls", "endpoint.get", "endpoint.search", "schema.ls", "schema.get",
          "schema.search", "describe", "version",
        ]),
      },
      [],
    ),
    output_schema: {
      "oneOf": Json::array([
        array_schema(command_descriptor_schema()),
        command_descriptor_schema(),
      ]),
    },
  }
}

///|
fn version_descriptor() -> CommandDescriptor {
  {
    name: "version",
    description: "Print the CLI version.",
    input_schema: object_schema({}, []),
    output_schema: string_schema("Version string."),
  }
}
