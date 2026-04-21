///|
pub(all) enum ApispecError {
  UsageError(String)
  ResourceNotFound(String)
  ParseError(String)
  AmbiguousMatch(String)
  UnsupportedSpec(String)
} derive(Eq, Debug)

///|
pub fn ApispecError::exit_code(self : ApispecError) -> Int {
  match self {
    UsageError(_) => 2
    ResourceNotFound(_) => 3
    ParseError(_) | UnsupportedSpec(_) => 4
    AmbiguousMatch(_) => 5
  }
}

///|
fn ApispecError::code(self : ApispecError) -> String {
  match self {
    UsageError(_) => "usage_error"
    ResourceNotFound(_) => "resource_not_found"
    ParseError(_) => "parse_error"
    AmbiguousMatch(_) => "ambiguous_match"
    UnsupportedSpec(_) => "unsupported_spec"
  }
}

///|
fn ApispecError::message(self : ApispecError) -> String {
  match self {
    UsageError(message)
    | ResourceNotFound(message)
    | ParseError(message)
    | AmbiguousMatch(message)
    | UnsupportedSpec(message) => message
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

///|
pub(all) struct EndpointGetOptions {
  no_resolve : Bool
} derive(Eq, Debug)

///|
pub(all) struct EndpointSubset {
  openapi_version : String
  endpoint : EndpointSummary
  operation : Json
  components : Json?
  warnings : Array[String]
} derive(Eq, Debug)

///|
pub(all) enum EndpointGetFormat {
  EndpointGetJson
  EndpointGetMarkdown
} derive(Eq, Debug)

///|
pub(all) struct SchemaSummary {
  name : String
  title : String?
  schema_type : String?
} derive(Eq, Debug)

///|
pub(all) enum SchemaListFormat {
  SchemaListJsonLines
  SchemaListMarkdown
  SchemaListQuiet
} derive(Eq, Debug)

///|
pub(all) struct SchemaGetOptions {
  with_usages : Bool
} derive(Eq, Debug)

///|
pub(all) struct SchemaSubset {
  openapi_version : String
  name : String
  schema : Json
  components : Json?
  usages : Array[EndpointSummary]?
  warnings : Array[String]
} derive(Eq, Debug)

///|
pub(all) enum SchemaGetFormat {
  SchemaGetJson
  SchemaGetMarkdown
} derive(Eq, Debug)
