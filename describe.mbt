///|
pub using @describe {type CommandDescriptor}

///|
pub fn describe_commands() -> Array[CommandDescriptor] {
  @describe.describe_commands()
}

///|
pub fn describe_command_names() -> Array[String] {
  @describe.describe_command_names()
}

///|
pub fn describe_command(
  name : String,
) -> Result[CommandDescriptor, ApispecError] {
  match @describe.describe_command(name) {
    Some(descriptor) => Ok(descriptor)
    None => Err(ResourceNotFound("command descriptor not found: \{name}"))
  }
}

///|
pub fn format_command_descriptors(
  descriptors : Array[CommandDescriptor],
) -> String {
  @describe.format_command_descriptors(descriptors)
}

///|
pub fn format_command_descriptor(descriptor : CommandDescriptor) -> String {
  @describe.format_command_descriptor(descriptor)
}
