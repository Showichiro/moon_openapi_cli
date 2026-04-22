///|
pub using @schema {
  type SchemaGetFormat,
  type SchemaGetOptions,
  type SchemaListFormat,
  type SchemaSearchFormat,
  type SchemaSearchOptions,
  type SchemaSearchResult,
  type SchemaSubset,
  type SchemaSummary,
}

///|
pub fn schema_get_options(with_usages : Bool) -> SchemaGetOptions {
  @schema.schema_get_options(with_usages)
}

///|
pub fn schema_search_options(limit : Int) -> SchemaSearchOptions {
  @schema.schema_search_options(limit)
}

///|
pub fn list_schemas_from_source(
  source : String,
) -> Result[Array[SchemaSummary], ApispecError] {
  @schema.list_schemas_from_source(source)
}

///|
pub fn list_schemas(
  document : Json,
) -> Result[Array[SchemaSummary], ApispecError] {
  @schema.list_schemas(document)
}

///|
pub fn get_schema_from_source(
  source : String,
  name : String,
  options~ : SchemaGetOptions,
) -> Result[SchemaSubset, ApispecError] {
  @schema.get_schema_from_source(source, name, options~)
}

///|
pub fn get_schema(
  document : Json,
  name : String,
  options~ : SchemaGetOptions,
) -> Result[SchemaSubset, ApispecError] {
  @schema.get_schema(document, name, options~)
}

///|
pub fn search_schemas_from_source(
  source : String,
  query : String,
  options~ : SchemaSearchOptions,
) -> Result[Array[SchemaSearchResult], ApispecError] {
  @schema.search_schemas_from_source(source, query, options~)
}

///|
pub fn search_schemas(
  document : Json,
  query : String,
  options~ : SchemaSearchOptions,
) -> Result[Array[SchemaSearchResult], ApispecError] {
  @schema.search_schemas(document, query, options~)
}

///|
pub fn format_schema_list(
  schemas : Array[SchemaSummary],
  format : SchemaListFormat,
) -> String {
  @schema.format_schema_list(schemas, format)
}

///|
pub fn format_schema_search_results(
  results : Array[SchemaSearchResult],
  format : SchemaSearchFormat,
) -> String {
  @schema.format_schema_search_results(results, format)
}

///|
pub fn format_schema_subset(
  subset : SchemaSubset,
  format : SchemaGetFormat,
) -> String {
  @schema.format_schema_subset(subset, format)
}
