///|
async fn exit_with_error(err : @lib.ApispecError) -> Unit {
  write_stderr(err.to_stderr_json() + "\n")
  exit_ffi(err.exit_code())
}

///|
async fn exit_with_error_context(
  err : @lib.ApispecError,
  input : String?,
  suggestion : String?,
) -> Unit {
  write_stderr(err.to_stderr_json_with_context(input, suggestion) + "\n")
  exit_ffi(err.exit_code())
}

///|
async fn exit_with_format_error(
  err : @lib.ApispecError,
  matches : @argparse.Matches,
) -> Unit {
  exit_with_error_context(
    err,
    option_value(matches, "format"),
    Some("supported formats: json, md"),
  )
}

///|
async fn exit_with_warning_format_error(
  err : @lib.ApispecError,
  matches : @argparse.Matches,
) -> Unit {
  exit_with_error_context(
    err,
    option_value(matches, "warnings"),
    Some("supported warnings: text, json, none"),
  )
}

///|
async fn exit_with_limit_error(
  err : @lib.ApispecError,
  matches : @argparse.Matches,
) -> Unit {
  exit_with_error_context(
    err,
    option_value(matches, "limit"),
    Some("limit must be a positive integer"),
  )
}

///|
async fn exit_with_operation_error(
  err : @lib.ApispecError,
  target : String,
  content : String,
  file : String,
) -> Unit {
  match err {
    @lib.ResourceNotFound(_) =>
      exit_with_error_context(
        err,
        Some(target),
        Some(endpoint_not_found_suggestion(target, content, file)),
      )
    @lib.AmbiguousMatch(_) =>
      exit_with_error_context(
        err,
        Some(target),
        Some("use an operationId or `METHOD PATH` to select one operation"),
      )
    _ => exit_with_error(err)
  }
}

///|
async fn exit_with_schema_error(
  err : @lib.ApispecError,
  name : String,
  content : String,
  file : String,
) -> Unit {
  match err {
    @lib.ResourceNotFound(_) =>
      exit_with_error_context(
        err,
        Some(name),
        Some(schema_not_found_suggestion(name, content, file)),
      )
    _ => exit_with_error(err)
  }
}

///|
fn describe_command_suggestion() -> String {
  "available subcommands: " + @lib.describe_command_names().join(", ")
}

///|
async fn exit_success(output : String) -> Unit {
  write_stdout(output)
  exit_ffi(0)
}

///|
async fn exit_success_output(output : String) -> Unit {
  if output.is_empty() {
    exit_success("")
  } else {
    exit_success(output + "\n")
  }
}

///|
extern "c" fn exit_ffi(code : Int) -> Unit = "exit"
