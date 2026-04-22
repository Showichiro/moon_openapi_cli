///|
using @errors {type ApispecError}

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
  inline_refs : Bool
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
pub(all) struct EndpointSearchOptions {
  tag : String?
  http_method : String?
  limit : Int
} derive(Eq, Debug)

///|
pub(all) struct EndpointSearchResult {
  operation_id : String
  target : String
  http_method : String
  path : String
  tags : Array[String]
  summary : String?
  score : Int
  matched_fields : Array[String]
} derive(Eq, Debug)

///|
pub(all) enum EndpointSearchFormat {
  EndpointSearchJsonLines
  EndpointSearchMarkdown
  EndpointSearchQuiet
} derive(Eq, Debug)
