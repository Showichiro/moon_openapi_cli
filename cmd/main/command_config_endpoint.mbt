///|
fn endpoint_command() -> @argparse.Command {
  @argparse.Command("endpoint", subcommand_required=true, subcommands=[
    endpoint_ls_command(),
    endpoint_get_command(),
    endpoint_search_command(),
  ])
}

///|
fn endpoint_ls_command() -> @argparse.Command {
  @argparse.Command(
    "ls",
    about="List OpenAPI operations",
    options=[
      input_file_option(),
      tag_option(),
      method_option(),
      output_format_option(),
    ],
    flags=[quiet_flag(), verbose_flag()],
  )
}

///|
fn endpoint_get_command() -> @argparse.Command {
  @argparse.Command(
    "get",
    about="Extract one OpenAPI operation",
    positionals=[
      @argparse.PositionArg(
        "target",
        about="operationId, METHOD PATH, or PATH",
        num_args=@argparse.ValueRange(lower=1, upper=2),
        allow_hyphen_values=true,
      ),
    ],
    options=[input_file_option(), output_format_option(), warnings_option()],
    flags=[
      @argparse.FlagArg(
        "no-resolve",
        about="Skip reachable component inclusion and external ref import.",
      ),
      @argparse.FlagArg(
        "inline-refs",
        about="Inline reachable internal $ref values in the emitted subset.",
      ),
      verbose_flag(),
    ],
  )
}

///|
fn endpoint_search_command() -> @argparse.Command {
  @argparse.Command(
    "search",
    about="Search OpenAPI operations",
    positionals=[search_query_position()],
    options=[
      input_file_option(),
      tag_option(),
      method_option(),
      limit_option(),
      output_format_option(),
    ],
    flags=[quiet_flag(), verbose_flag()],
  )
}
