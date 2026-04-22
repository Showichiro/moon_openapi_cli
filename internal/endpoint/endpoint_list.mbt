///|
pub fn endpoint_list_options(
  tag : String?,
  http_method : String?,
) -> EndpointListOptions {
  { tag, http_method }
}

///|
pub fn list_endpoints_from_source(
  source : String,
  options~ : EndpointListOptions,
) -> Result[Array[EndpointSummary], ApispecError] {
  match @source.parse_json_object_source(source) {
    Ok(json) => list_endpoints(json, options~)
    Err(err) => Err(err)
  }
}

///|
pub fn list_endpoints(
  document : Json,
  options~ : EndpointListOptions,
) -> Result[Array[EndpointSummary], ApispecError] {
  match @normalize.normalize_document(document) {
    Err(err) => Err(err)
    Ok(document) =>
      match list_endpoints_normalized(document, options~) {
        Err(err) => Err(err)
        Ok(endpoints) => Ok(endpoints)
      }
  }
}

///|
fn list_endpoints_normalized(
  document : Json,
  options~ : EndpointListOptions,
) -> Result[Array[EndpointSummary], ApispecError] {
  match document {
    Object(root) =>
      match root.get("paths") {
        Some(Object(paths)) => Ok(extract_paths(paths, options))
        Some(_) => Err(ParseError("expected 'paths' to be an object"))
        None => Err(ParseError("missing required 'paths' object"))
      }
    _ => Err(ParseError("expected JSON object input"))
  }
}

///|
fn extract_paths(
  paths : Map[String, Json],
  options : EndpointListOptions,
) -> Array[EndpointSummary] {
  let endpoints : Array[EndpointSummary] = []
  for path, path_item in paths {
    if path_item is Object(path_item_obj) {
      for method_name, operation_json in path_item_obj {
        let http_method = method_name.to_upper()
        if @http_method.is_http_method(http_method) {
          if operation_json is Object(operation) {
            if build_endpoint(path, http_method, operation) is Some(endpoint) {
              if endpoint_matches(endpoint, options) {
                endpoints.push(endpoint)
              }
            }
          }
        }
      }
    }
  }
  sort_endpoints(endpoints)
  endpoints
}

///|
fn endpoint_matches(
  endpoint : EndpointSummary,
  options : EndpointListOptions,
) -> Bool {
  let method_matches = match options.http_method {
    Some(http_method) =>
      endpoint.http_method.equal_ignore_ascii_case(http_method)
    None => true
  }
  let tag_matches = match options.tag {
    Some(tag) => endpoint.tags.contains(tag)
    None => true
  }
  method_matches && tag_matches
}
