///|
pub(all) enum ApispecError {
  UsageError(String)
  ParseError(String)
  UnsupportedSpec(String)
} derive(Eq, Debug)

///|
pub fn ApispecError::exit_code(self : ApispecError) -> Int {
  match self {
    UsageError(_) => 2
    ParseError(_) | UnsupportedSpec(_) => 4
  }
}

///|
fn ApispecError::code(self : ApispecError) -> String {
  match self {
    UsageError(_) => "usage_error"
    ParseError(_) => "parse_error"
    UnsupportedSpec(_) => "unsupported_spec"
  }
}

///|
fn ApispecError::message(self : ApispecError) -> String {
  match self {
    UsageError(message) | ParseError(message) | UnsupportedSpec(message) =>
      message
  }
}

///|
pub fn ApispecError::to_stderr_json(self : ApispecError) -> String {
  let json : Json = {
    "error": Json::string(self.code()),
    "message": Json::string(self.message()),
  }
  json.stringify()
}

///|
pub(all) struct EndpointSummary {
  operation_id : String
  http_method : String
  path : String
  tags : Array[String]
  summary : String?
} derive(Eq, Debug)

///|
pub(all) struct EndpointListOptions {
  tag : String?
  http_method : String?
} derive(Eq, Debug)

///|
pub(all) enum EndpointListFormat {
  JsonLines
  Markdown
  Quiet
} derive(Eq, Debug)
