///|
fn schema_command() -> @argparse.Command {
  @argparse.Command("schema", subcommand_required=true, subcommands=[
    schema_ls_command(),
    schema_get_command(),
    schema_search_command(),
  ])
}

///|
fn schema_ls_command() -> @argparse.Command {
  @argparse.Command(
    "ls",
    about="List OpenAPI component schemas",
    options=[input_file_option(), output_format_option()],
    flags=[quiet_flag(), verbose_flag()],
  )
}

///|
fn schema_get_command() -> @argparse.Command {
  @argparse.Command(
    "get",
    about="Extract one OpenAPI component schema",
    positionals=[
      @argparse.PositionArg(
        "name",
        about="Schema name under components.schemas",
        num_args=@argparse.ValueRange::single(),
        allow_hyphen_values=true,
      ),
    ],
    options=[input_file_option(), output_format_option(), warnings_option()],
    flags=[@argparse.FlagArg("with-usages"), verbose_flag()],
  )
}

///|
fn schema_search_command() -> @argparse.Command {
  @argparse.Command(
    "search",
    about="Search OpenAPI component schemas",
    positionals=[search_query_position()],
    options=[input_file_option(), limit_option(), output_format_option()],
    flags=[quiet_flag(), verbose_flag()],
  )
}
