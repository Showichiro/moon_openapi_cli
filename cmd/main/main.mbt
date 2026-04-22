///|
const VERSION : String = "0.1.5"

///|
async fn main {
  let args = @env.args()
  let argv = if args.length() > 1 { args[1:] } else { [] }
  let parsed : Result[@argparse.Matches, _] = try? command().parse(argv~)
  match parsed {
    Ok(matches) => dispatch(matches)
    Err(err) => exit_with_error(@lib.ApispecError::UsageError(err.to_string()))
  }
}

///|
async fn dispatch(matches : @argparse.Matches) -> Unit {
  match matches.subcommand {
    Some(("version", _)) => exit_success(VERSION + "\n")
    Some(("describe", describe_matches)) => describe(describe_matches)
    Some(("endpoint", endpoint_matches)) =>
      match endpoint_matches.subcommand {
        Some(("ls", ls_matches)) => endpoint_ls(ls_matches)
        Some(("get", get_matches)) => endpoint_get(get_matches)
        Some(("search", search_matches)) => endpoint_search(search_matches)
        _ =>
          exit_with_error(
            @lib.ApispecError::UsageError("missing endpoint subcommand"),
          )
      }
    Some(("schema", schema_matches)) =>
      match schema_matches.subcommand {
        Some(("ls", ls_matches)) => schema_ls(ls_matches)
        Some(("get", get_matches)) => schema_get(get_matches)
        Some(("search", search_matches)) => schema_search(search_matches)
        _ =>
          exit_with_error(
            @lib.ApispecError::UsageError("missing schema subcommand"),
          )
      }
    _ => exit_with_error(@lib.ApispecError::UsageError("missing subcommand"))
  }
}

///|
async fn describe(matches : @argparse.Matches) -> Unit {
  match option_value(matches, "subcommand") {
    Some(name) =>
      match @lib.describe_command(name) {
        Ok(descriptor) =>
          exit_success(@lib.format_command_descriptor(descriptor) + "\n")
        Err(err) =>
          exit_with_error_context(
            err,
            Some(name),
            Some(describe_command_suggestion()),
          )
      }
    None =>
      exit_success(
        @lib.format_command_descriptors(@lib.describe_commands()) + "\n",
      )
  }
}
