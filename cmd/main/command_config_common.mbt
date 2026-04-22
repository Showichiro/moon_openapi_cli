///|
fn input_file_option() -> @argparse.OptionArg {
  @argparse.OptionArg(
    "file",
    short='f',
    about="Input JSON file, http(s) URL, or '-' for stdin.",
    default_values=["-"],
  )
}

///|
fn output_format_option() -> @argparse.OptionArg {
  @argparse.OptionArg("format", about="Output format: json or md", default_values=[
    "json",
  ])
}

///|
fn warnings_option() -> @argparse.OptionArg {
  @argparse.OptionArg("warnings", about="Warning output: text, json, or none", default_values=[
    "text",
  ])
}

///|
fn limit_option() -> @argparse.OptionArg {
  @argparse.OptionArg("limit", about="Maximum results", default_values=["10"])
}

///|
fn tag_option() -> @argparse.OptionArg {
  @argparse.OptionArg("tag", about="Filter by tag")
}

///|
fn method_option() -> @argparse.OptionArg {
  @argparse.OptionArg("method", about="Filter by HTTP method")
}

///|
fn search_query_position() -> @argparse.PositionArg {
  @argparse.PositionArg(
    "query",
    about="Search query",
    num_args=@argparse.ValueRange(lower=1),
    allow_hyphen_values=true,
  )
}

///|
fn quiet_flag() -> @argparse.FlagArg {
  @argparse.FlagArg("quiet", short='q')
}

///|
fn verbose_flag() -> @argparse.FlagArg {
  @argparse.FlagArg("verbose")
}
