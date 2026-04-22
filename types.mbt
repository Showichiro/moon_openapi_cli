///|
pub using @errors {type ApispecError}

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

///|
pub(all) struct SchemaSearchOptions {
  limit : Int
} derive(Eq, Debug)

///|
pub(all) struct SchemaSearchResult {
  name : String
  title : String?
  schema_type : String?
  score : Int
  matched_fields : Array[String]
} derive(Eq, Debug)

///|
pub(all) enum SchemaSearchFormat {
  SchemaSearchJsonLines
  SchemaSearchMarkdown
  SchemaSearchQuiet
} derive(Eq, Debug)
