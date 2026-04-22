///|
async fn read_command_input(
  trace : VerboseTrace,
  matches : @argparse.Matches,
) -> Result[(String, String), String] {
  let file = option_value(matches, "file").unwrap_or("-")
  match read_input_with_trace(trace, file) {
    Err(message) => Err(message)
    Ok(content) => Ok((file, content))
  }
}

///|
async fn exit_with_input_error(trace : VerboseTrace, message : String) -> Unit {
  write_trace_total(trace)
  exit_with_error(@lib.ParseError(message))
}
