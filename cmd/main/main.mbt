///|
const VERSION : String = "0.1.0"

///|
fn main {
  let args = @env.args()
  let argv = if args.length() > 1 { args[1:] } else { [] }
  let parsed : Result[@argparse.Matches, _] = try? command().parse(argv~)
  match parsed {
    Ok(matches) => dispatch(matches)
    Err(err) => exit_with_error(@lib.UsageError(err.to_string()))
  }
}

///|
fn command() -> @argparse.Command {
  @argparse.Command(
    "apispec",
    about="Agent-friendly OpenAPI extraction CLI",
    version=VERSION,
    subcommand_required=true,
    subcommands=[
      @argparse.Command("endpoint", subcommand_required=true, subcommands=[
        @argparse.Command(
          "ls",
          about="List OpenAPI operations",
          options=[
            @argparse.OptionArg(
              "file",
              short='f',
              about="Input JSON file. Use '-' for stdin.",
              default_values=["-"],
            ),
            @argparse.OptionArg("tag", about="Filter by tag"),
            @argparse.OptionArg("method", about="Filter by HTTP method"),
            @argparse.OptionArg("format", about="Output format: json or md", default_values=[
              "json",
            ]),
          ],
          flags=[@argparse.FlagArg("quiet", short='q')],
        ),
      ]),
      @argparse.Command("version", about="Print version"),
    ],
  )
}

///|
fn dispatch(matches : @argparse.Matches) -> Unit {
  match matches.subcommand {
    Some(("version", _)) => exit_success(VERSION + "\n")
    Some(("endpoint", endpoint_matches)) =>
      match endpoint_matches.subcommand {
        Some(("ls", ls_matches)) => endpoint_ls(ls_matches)
        _ => exit_with_error(@lib.UsageError("missing endpoint subcommand"))
      }
    _ => exit_with_error(@lib.UsageError("missing subcommand"))
  }
}

///|
fn endpoint_ls(matches : @argparse.Matches) -> Unit {
  let file = option_value(matches, "file").unwrap_or("-")
  let content_result = if file == "-" { read_stdin() } else { read_file(file) }
  match content_result {
    Err(message) => exit_with_error(@lib.ParseError(message))
    Ok(content) => {
      let options = @lib.endpoint_list_options(
        option_value(matches, "tag"),
        option_value(matches, "method"),
      )
      match @lib.list_endpoints_from_source(content, options~) {
        Err(err) => exit_with_error(err)
        Ok(endpoints) => {
          let format = resolve_format(matches)
          match format {
            Err(err) => exit_with_error(err)
            Ok(format) => {
              let output = @lib.format_endpoint_list(endpoints, format)
              if output.is_empty() {
                exit_success("")
              } else {
                exit_success(output + "\n")
              }
            }
          }
        }
      }
    }
  }
}

///|
fn option_value(matches : @argparse.Matches, name : String) -> String? {
  match matches.values.get(name) {
    Some(values) =>
      if values.length() > 0 {
        Some(values[values.length() - 1])
      } else {
        None
      }
    None => None
  }
}

///|
fn resolve_format(
  matches : @argparse.Matches,
) -> Result[@lib.EndpointListFormat, @lib.ApispecError] {
  if matches.flags.get_or_default("quiet", false) {
    Ok(@lib.Quiet)
  } else {
    match option_value(matches, "format").unwrap_or("json") {
      "json" => Ok(@lib.JsonLines)
      "md" => Ok(@lib.Markdown)
      value => Err(@lib.UsageError("unsupported format: \{value}"))
    }
  }
}

///|
fn exit_with_error(err : @lib.ApispecError) -> Unit {
  write_stderr(err.to_stderr_json() + "\n")
  exit_ffi(err.exit_code())
}

///|
fn exit_success(output : String) -> Unit {
  write_stdout(output)
  exit_ffi(0)
}

///|
fn read_file(path : String) -> Result[String, String] {
  decode_io_result(read_file_ffi(@utf8.encode(path)))
}

///|
fn read_stdin() -> Result[String, String] {
  decode_io_result(read_stdin_ffi())
}

///|
fn decode_io_result(bytes : Bytes) -> Result[String, String] {
  if bytes.length() == 0 {
    Err("I/O operation returned an empty status payload")
  } else {
    let payload = @utf8.decode_lossy(bytes[1:])
    if bytes[0].to_int() == 0 {
      Ok(payload)
    } else {
      Err(payload)
    }
  }
}

///|
fn write_stdout(output : String) -> Unit {
  write_stdout_ffi(@utf8.encode(output))
}

///|
fn write_stderr(output : String) -> Unit {
  write_stderr_ffi(@utf8.encode(output))
}

///|
#borrow(path)
extern "c" fn read_file_ffi(path : Bytes) -> Bytes = "moonbit_apispec_read_file"

///|
extern "c" fn read_stdin_ffi() -> Bytes = "moonbit_apispec_read_stdin"

///|
#borrow(output)
extern "c" fn write_stdout_ffi(output : Bytes) -> Unit = "moonbit_apispec_write_stdout"

///|
#borrow(output)
extern "c" fn write_stderr_ffi(output : Bytes) -> Unit = "moonbit_apispec_write_stderr"

///|
extern "c" fn exit_ffi(code : Int) -> Unit = "exit"
