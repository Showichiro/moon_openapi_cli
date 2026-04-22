///|
const GET : String = "GET"

///|
const POST : String = "POST"

///|
const PUT : String = "PUT"

///|
const DELETE : String = "DELETE"

///|
const PATCH : String = "PATCH"

///|
const OPTIONS : String = "OPTIONS"

///|
const HEAD : String = "HEAD"

///|
const TRACE : String = "TRACE"

///|
pub fn endpoint_list_options(
  tag : String?,
  http_method : String?,
) -> EndpointListOptions {
  { tag, http_method }
}

///|
pub fn endpoint_get_options(no_resolve : Bool) -> EndpointGetOptions {
  { no_resolve, }
}

///|
pub fn list_endpoints_from_source(
  source : String,
  options~ : EndpointListOptions,
) -> Result[Array[EndpointSummary], ApispecError] {
  match parse_json_object_source(source) {
    Ok(json) => list_endpoints(json, options~)
    Err(err) => Err(err)
  }
}

///|
pub fn list_endpoints(
  document : Json,
  options~ : EndpointListOptions,
) -> Result[Array[EndpointSummary], ApispecError] {
  match normalize_document(document) {
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
        if is_http_method(http_method) {
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
fn build_endpoint(
  path : String,
  http_method : String,
  operation : Map[String, Json],
) -> EndpointSummary? {
  let tags = extract_tags(operation)
  let operation_id = match operation.get("operationId") {
    Some(String(id)) =>
      if id.is_empty() {
        "\{http_method} \{path}"
      } else {
        id
      }
    _ => "\{http_method} \{path}"
  }
  let summary = match operation.get("summary") {
    Some(String(value)) => Some(value)
    _ => None
  }
  Some({ operation_id, http_method, path, tags, summary })
}

///|
fn extract_tags(operation : Map[String, Json]) -> Array[String] {
  match operation.get("tags") {
    Some(Array(values)) => {
      let tags : Array[String] = []
      for value in values {
        if value is String(tag) {
          tags.push(tag)
        }
      }
      tags
    }
    _ => []
  }
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

///|
fn is_http_method(http_method : String) -> Bool {
  http_method == GET ||
  http_method == POST ||
  http_method == PUT ||
  http_method == DELETE ||
  http_method == PATCH ||
  http_method == OPTIONS ||
  http_method == HEAD ||
  http_method == TRACE
}

///|
fn method_rank(http_method : String) -> Int {
  match http_method {
    "GET" => 0
    "POST" => 1
    "PUT" => 2
    "PATCH" => 3
    "DELETE" => 4
    "OPTIONS" => 5
    "HEAD" => 6
    "TRACE" => 7
    _ => 99
  }
}

///|
fn compare_endpoints(left : EndpointSummary, right : EndpointSummary) -> Int {
  let path_cmp = left.path.lexical_compare(right.path)
  if path_cmp != 0 {
    path_cmp
  } else {
    let method_cmp = method_rank(left.http_method) -
      method_rank(right.http_method)
    if method_cmp != 0 {
      method_cmp
    } else {
      left.operation_id.lexical_compare(right.operation_id)
    }
  }
}

///|
fn sort_endpoints(endpoints : Array[EndpointSummary]) -> Unit {
  endpoints.sort_by(compare_endpoints)
}
