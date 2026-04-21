///|
const VERSION : String = "0.1.0"

///|
async fn main {
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
              about="Input JSON file, http(s) URL, or '-' for stdin.",
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
          options=[
            @argparse.OptionArg(
              "file",
              short='f',
              about="Input JSON file, http(s) URL, or '-' for stdin.",
              default_values=["-"],
            ),
            @argparse.OptionArg("format", about="Output format: json or md", default_values=[
              "json",
            ]),
          ],
          flags=[@argparse.FlagArg("no-resolve")],
        ),
      ]),
      @argparse.Command("schema", subcommand_required=true, subcommands=[
        @argparse.Command(
          "ls",
          about="List OpenAPI component schemas",
          options=[
            @argparse.OptionArg(
              "file",
              short='f',
              about="Input JSON file, http(s) URL, or '-' for stdin.",
              default_values=["-"],
            ),
            @argparse.OptionArg("format", about="Output format: json or md", default_values=[
              "json",
            ]),
          ],
          flags=[@argparse.FlagArg("quiet", short='q')],
        ),
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
          options=[
            @argparse.OptionArg(
              "file",
              short='f',
              about="Input JSON file, http(s) URL, or '-' for stdin.",
              default_values=["-"],
            ),
            @argparse.OptionArg("format", about="Output format: json or md", default_values=[
              "json",
            ]),
          ],
          flags=[@argparse.FlagArg("with-usages")],
        ),
      ]),
      @argparse.Command(
        "describe",
        about="Describe available apispec commands",
        options=[
          @argparse.OptionArg(
            "subcommand",
            about="Descriptor name such as endpoint.get",
          ),
        ],
      ),
      @argparse.Command("version", about="Print version"),
    ],
  )
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
        _ => exit_with_error(@lib.UsageError("missing endpoint subcommand"))
      }
    Some(("schema", schema_matches)) =>
      match schema_matches.subcommand {
        Some(("ls", ls_matches)) => schema_ls(ls_matches)
        Some(("get", get_matches)) => schema_get(get_matches)
        _ => exit_with_error(@lib.UsageError("missing schema subcommand"))
      }
    _ => exit_with_error(@lib.UsageError("missing subcommand"))
  }
}

///|
fn describe(matches : @argparse.Matches) -> Unit {
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

///|
async fn endpoint_ls(matches : @argparse.Matches) -> Unit {
  let file = option_value(matches, "file").unwrap_or("-")
  let content_result = read_input(file)
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
          let format = resolve_list_format(matches)
          match format {
            Err(err) => exit_with_format_error(err, matches)
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
async fn endpoint_get(matches : @argparse.Matches) -> Unit {
  let target_result = positional_target(matches)
  match target_result {
    Err(err) => exit_with_error(err)
    Ok(target) => {
      let file = option_value(matches, "file").unwrap_or("-")
      let content_result = read_input(file)
      match content_result {
        Err(message) => exit_with_error(@lib.ParseError(message))
        Ok(content) => {
          let options = @lib.endpoint_get_options(
            matches.flags.get_or_default("no-resolve", false),
          )
          match @lib.get_endpoint_from_source(content, target, options~) {
            Err(err) => exit_with_operation_error(err, target)
            Ok(subset) => {
              for warning in subset.warnings {
                write_stderr("warning: \{warning}\n")
              }
              let format = resolve_get_format(matches)
              match format {
                Err(err) => exit_with_format_error(err, matches)
                Ok(format) => {
                  let output = @lib.format_endpoint_subset(subset, format)
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
  }
}

///|
async fn schema_ls(matches : @argparse.Matches) -> Unit {
  let file = option_value(matches, "file").unwrap_or("-")
  let content_result = read_input(file)
  match content_result {
    Err(message) => exit_with_error(@lib.ParseError(message))
    Ok(content) =>
      match @lib.list_schemas_from_source(content) {
        Err(err) => exit_with_error(err)
        Ok(schemas) => {
          let format = resolve_schema_list_format(matches)
          match format {
            Err(err) => exit_with_format_error(err, matches)
            Ok(format) => {
              let output = @lib.format_schema_list(schemas, format)
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

///|
async fn schema_get(matches : @argparse.Matches) -> Unit {
  let name_result = single_positional(matches, "name")
  match name_result {
    Err(err) => exit_with_error(err)
    Ok(name) => {
      let file = option_value(matches, "file").unwrap_or("-")
      let content_result = read_input(file)
      match content_result {
        Err(message) => exit_with_error(@lib.ParseError(message))
        Ok(content) => {
          let options = @lib.schema_get_options(
            matches.flags.get_or_default("with-usages", false),
          )
          match @lib.get_schema_from_source(content, name, options~) {
            Err(err) => exit_with_schema_error(err, name)
            Ok(subset) => {
              for warning in subset.warnings {
                write_stderr("warning: \{warning}\n")
              }
              let format = resolve_schema_get_format(matches)
              match format {
                Err(err) => exit_with_format_error(err, matches)
                Ok(format) => {
                  let output = @lib.format_schema_subset(subset, format)
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
  }
}

///|
fn positional_target(
  matches : @argparse.Matches,
) -> Result[String, @lib.ApispecError] {
  match matches.values.get("target") {
    Some(values) =>
      match values.length() {
        1 => Ok(values[0])
        2 => Ok(values[0] + " " + values[1])
        _ => Err(@lib.UsageError("expected one endpoint target"))
      }
    None => Err(@lib.UsageError("expected one endpoint target"))
  }
}

///|
fn single_positional(
  matches : @argparse.Matches,
  name : String,
) -> Result[String, @lib.ApispecError] {
  match matches.values.get(name) {
    Some(values) =>
      if values.length() == 1 {
        Ok(values[0])
      } else {
        Err(@lib.UsageError("expected one \{name} value"))
      }
    None => Err(@lib.UsageError("expected one \{name} value"))
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
fn resolve_list_format(
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
fn resolve_get_format(
  matches : @argparse.Matches,
) -> Result[@lib.EndpointGetFormat, @lib.ApispecError] {
  match option_value(matches, "format").unwrap_or("json") {
    "json" => Ok(@lib.EndpointGetJson)
    "md" => Ok(@lib.EndpointGetMarkdown)
    value => Err(@lib.UsageError("unsupported format: \{value}"))
  }
}

///|
fn resolve_schema_list_format(
  matches : @argparse.Matches,
) -> Result[@lib.SchemaListFormat, @lib.ApispecError] {
  if matches.flags.get_or_default("quiet", false) {
    Ok(@lib.SchemaListQuiet)
  } else {
    match option_value(matches, "format").unwrap_or("json") {
      "json" => Ok(@lib.SchemaListJsonLines)
      "md" => Ok(@lib.SchemaListMarkdown)
      value => Err(@lib.UsageError("unsupported format: \{value}"))
    }
  }
}

///|
fn resolve_schema_get_format(
  matches : @argparse.Matches,
) -> Result[@lib.SchemaGetFormat, @lib.ApispecError] {
  match option_value(matches, "format").unwrap_or("json") {
    "json" => Ok(@lib.SchemaGetJson)
    "md" => Ok(@lib.SchemaGetMarkdown)
    value => Err(@lib.UsageError("unsupported format: \{value}"))
  }
}

///|
fn exit_with_error(err : @lib.ApispecError) -> Unit {
  write_stderr(err.to_stderr_json() + "\n")
  exit_ffi(err.exit_code())
}

///|
fn exit_with_error_context(
  err : @lib.ApispecError,
  input : String?,
  suggestion : String?,
) -> Unit {
  write_stderr(err.to_stderr_json_with_context(input, suggestion) + "\n")
  exit_ffi(err.exit_code())
}

///|
fn exit_with_format_error(
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
fn exit_with_operation_error(err : @lib.ApispecError, target : String) -> Unit {
  match err {
    @lib.ResourceNotFound(_) =>
      exit_with_error_context(
        err,
        Some(target),
        Some(
          "run `apispec endpoint ls -f <file>` to inspect available operations",
        ),
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
fn exit_with_schema_error(err : @lib.ApispecError, name : String) -> Unit {
  match err {
    @lib.ResourceNotFound(_) =>
      exit_with_error_context(
        err,
        Some(name),
        Some("run `apispec schema ls -f <file>` to inspect available schemas"),
      )
    _ => exit_with_error(err)
  }
}

///|
fn describe_command_suggestion() -> String {
  "available subcommands: " + @lib.describe_command_names().join(", ")
}

///|
fn exit_success(output : String) -> Unit {
  write_stdout(output)
  exit_ffi(0)
}

///|
enum InputSource {
  Stdin
  LocalFile(String)
  RemoteUrl(String)
  UnsupportedUrl(String)
} derive(Eq, Debug)

///|
fn classify_input_source(source : String) -> InputSource {
  if source == "-" {
    Stdin
  } else if source.has_prefix("http://") || source.has_prefix("https://") {
    RemoteUrl(source)
  } else {
    match source.find("://") {
      Some(protocol_len) => UnsupportedUrl(source[:protocol_len].to_string())
      None => LocalFile(source)
    }
  }
}

///|
async fn read_input(source : String) -> Result[String, String] {
  match classify_input_source(source) {
    Stdin => read_stdin()
    LocalFile(path) => read_file(path)
    RemoteUrl(url) => fetch_url(url)
    UnsupportedUrl(scheme) => Err("unsupported input URL scheme: \{scheme}")
  }
}

///|
async fn fetch_url(url : String) -> Result[String, String] {
  match @async.with_timeout_opt(10000, () => fetch_url_without_timeout(url)) {
    Some(result) => result
    None => Err("timed out fetching '\{url}' after 10000ms")
  }
}

///|
async fn fetch_url_without_timeout(url : String) -> Result[String, String] {
  let result = try? @http.get(url)
  match result {
    Err(err) => Err("failed to fetch '\{url}': \{err}")
    Ok((response, body)) =>
      if response.code >= 200 && response.code < 300 {
        let text_result = try? body.text()
        match text_result {
          Ok(text) => Ok(text)
          Err(err) =>
            Err("failed to decode response body from '\{url}': \{err}")
        }
      } else {
        Err(
          "failed to fetch '\{url}': HTTP \{response.code} \{response.reason}",
        )
      }
  }
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
