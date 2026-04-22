///|
pub(all) struct OperationCandidate {
  endpoint : EndpointSummary
  operation : Json
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
fn compare_endpoints(left : EndpointSummary, right : EndpointSummary) -> Int {
  let path_cmp = left.path.lexical_compare(right.path)
  if path_cmp != 0 {
    path_cmp
  } else {
    let method_cmp = @http_method.rank(left.http_method) -
      @http_method.rank(right.http_method)
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

///|
pub fn collect_operation_candidates(
  paths : Map[String, Json],
) -> Array[OperationCandidate] {
  let candidates : Array[OperationCandidate] = []
  for path, path_item in paths {
    if path_item is Object(path_item_obj) {
      for method_name, operation_json in path_item_obj {
        let http_method = method_name.to_upper()
        if @http_method.is_http_method(http_method) {
          if operation_json is Object(operation) {
            if build_endpoint(path, http_method, operation) is Some(endpoint) {
              candidates.push({ endpoint, operation: operation_json })
            }
          }
        }
      }
    }
  }
  sort_operation_candidates(candidates)
  candidates
}

///|
fn sort_operation_candidates(candidates : Array[OperationCandidate]) -> Unit {
  candidates.sort_by((left, right) => {
    compare_endpoints(left.endpoint, right.endpoint)
  })
}
