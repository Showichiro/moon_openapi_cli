///|
fn command() -> @argparse.Command {
  @argparse.Command(
    "apispec",
    about="Agent-friendly OpenAPI extraction CLI",
    version=VERSION,
    subcommand_required=true,
    subcommands=[
      endpoint_command(),
      schema_command(),
      describe_command(),
      @argparse.Command("version", about="Print version"),
    ],
  )
}

///|
fn describe_command() -> @argparse.Command {
  @argparse.Command("describe", about="Describe available apispec commands", options=[
    @argparse.OptionArg(
      "subcommand",
      about="Descriptor name such as endpoint.get",
    ),
  ])
}
