///|
pub(all) struct CommandDescriptor {
  name : String
  description : String
  input_schema : Json
  output_schema : Json
} derive(Eq, Debug)

///|
pub fn CommandDescriptor::to_json(self : CommandDescriptor) -> Json {
  {
    "name": Json::string(self.name),
    "description": Json::string(self.description),
    "inputSchema": self.input_schema,
    "outputSchema": self.output_schema,
  }
}

///|
pub fn describe_commands() -> Array[CommandDescriptor] {
  [
    endpoint_ls_descriptor(),
    endpoint_get_descriptor(),
    schema_ls_descriptor(),
    schema_get_descriptor(),
    describe_descriptor(),
    version_descriptor(),
  ]
}

///|
pub fn describe_command_names() -> Array[String] {
  describe_commands().map(descriptor => descriptor.name)
}

///|
pub fn describe_command(
  name : String,
) -> Result[CommandDescriptor, ApispecError] {
  let matches = describe_commands().filter(descriptor => descriptor.name == name)
  match matches.length() {
    1 => Ok(matches[0])
    _ => Err(ResourceNotFound("command descriptor not found: \{name}"))
  }
}

///|
pub fn format_command_descriptors(
  descriptors : Array[CommandDescriptor],
) -> String {
  Json::array(descriptors.map(descriptor => descriptor.to_json())).stringify(
    indent=2,
  )
}

///|
pub fn format_command_descriptor(descriptor : CommandDescriptor) -> String {
  descriptor.to_json().stringify(indent=2)
}

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
    description: "Extract one OpenAPI operation with reachable components.",
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
        "noResolve": boolean_schema("Skip reachable component collection."),
        "verbose": boolean_schema("Emit phase timing JSON Lines on stderr."),
      },
      ["target"],
    ),
    output_schema: endpoint_subset_schema(),
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
fn describe_descriptor() -> CommandDescriptor {
  {
    name: "describe",
    description: "Describe available apispec commands as MCP-compatible metadata.",
    input_schema: object_schema(
      {
        "subcommand": enum_schema("Optional descriptor name to return.", [
          "endpoint.ls", "endpoint.get", "schema.ls", "schema.get", "describe", "version",
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

///|
fn object_schema(
  properties : Map[String, Json],
  required : Array[String],
) -> Json {
  let schema : Map[String, Json] = {
    "type": Json::string("object"),
    "properties": Json::object(properties),
    "additionalProperties": Json::boolean(false),
  }
  if required.length() > 0 {
    schema["required"] = Json::array(required.map(name => Json::string(name)))
  }
  Json::object(schema)
}

///|
fn array_schema(items : Json) -> Json {
  { "type": Json::string("array"), "items": items }
}

///|
fn string_schema(description : String) -> Json {
  { "type": Json::string("string"), "description": Json::string(description) }
}

///|
fn boolean_schema(description : String) -> Json {
  { "type": Json::string("boolean"), "description": Json::string(description) }
}

///|
fn enum_schema(description : String, values : Array[String]) -> Json {
  let schema : Map[String, Json] = {
    "type": Json::string("string"),
    "description": Json::string(description),
    "enum": Json::array(values.map(value => Json::string(value))),
  }
  Json::object(schema)
}

///|
fn json_schema(description : String) -> Json {
  { "description": Json::string(description) }
}
