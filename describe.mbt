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
    endpoint_search_descriptor(),
    schema_ls_descriptor(),
    schema_get_descriptor(),
    schema_search_descriptor(),
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
