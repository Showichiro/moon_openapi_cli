///|
using @endpoint {type EndpointSummary}

///|
using @errors {type ApispecError}

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
