///|
pub fn endpoint_search_options(
  tag : String?,
  http_method : String?,
  limit : Int,
) -> EndpointSearchOptions {
  { tag, http_method, limit }
}

///|
pub fn schema_search_options(limit : Int) -> SchemaSearchOptions {
  { limit, }
}

///|
pub fn search_endpoints_from_source(
  source : String,
  query : String,
  options~ : EndpointSearchOptions,
) -> Result[Array[EndpointSearchResult], ApispecError] {
  match parse_json_object_source(source) {
    Ok(json) => search_endpoints(json, query, options~)
    Err(err) => Err(err)
  }
}

///|
pub fn search_endpoints(
  document : Json,
  query : String,
  options~ : EndpointSearchOptions,
) -> Result[Array[EndpointSearchResult], ApispecError] {
  match validate_search_input(query, options.limit) {
    Err(err) => Err(err)
    Ok(query) =>
      match
        list_endpoints(
          document,
          options=endpoint_list_options(options.tag, options.http_method),
        ) {
        Err(err) => Err(err)
        Ok(endpoints) =>
          Ok(score_endpoint_results(endpoints, query, options.limit))
      }
  }
}

///|
pub fn search_schemas_from_source(
  source : String,
  query : String,
  options~ : SchemaSearchOptions,
) -> Result[Array[SchemaSearchResult], ApispecError] {
  match parse_json_object_source(source) {
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
  match validate_search_input(query, options.limit) {
    Err(err) => Err(err)
    Ok(query) =>
      match normalize_document(document) {
        Err(err) => Err(err)
        Ok(document) =>
          search_schemas_normalized(document, query, options.limit)
      }
  }
}

///|
fn validate_search_input(
  query : String,
  limit : Int,
) -> Result[String, ApispecError] {
  let query = query.trim().to_string()
  if query.is_empty() {
    Err(UsageError("expected non-empty search query"))
  } else if limit <= 0 {
    Err(UsageError("limit must be greater than 0"))
  } else {
    Ok(query)
  }
}
