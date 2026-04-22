///|
pub fn schema_search_options(limit : Int) -> SchemaSearchOptions {
  { limit, }
}

///|
pub fn search_schemas_from_source(
  source : String,
  query : String,
  options~ : SchemaSearchOptions,
) -> Result[Array[SchemaSearchResult], ApispecError] {
  match @source.parse_json_object_source(source) {
    Ok(json) => search_schemas(json, query, options~)
    Err(err) => Err(err)
  }
}

///|
pub fn search_schemas(
  document : Json,
  query : String,
  options~ : SchemaSearchOptions,
) -> Result[Array[SchemaSearchResult], ApispecError] {
  match @search.validate_search_input(query, options.limit) {
    Err(err) => Err(err)
    Ok(query) =>
      match @normalize.normalize_document(document) {
        Err(err) => Err(err)
        Ok(document) =>
          search_schemas_normalized(document, query, options.limit)
      }
  }
}
