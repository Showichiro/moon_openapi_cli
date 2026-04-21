///|
priv struct OperationCandidate {
  endpoint : EndpointSummary
  operation : Json
}

///|
pub fn get_endpoint_from_source(
  source : String,
  target : String,
  options~ : EndpointGetOptions,
) -> Result[EndpointSubset, ApispecError] {
  let trimmed = source.trim_start()
  if !trimmed.has_prefix("{") {
    Err(ParseError("expected JSON object input"))
  } else {
    let parsed : Result[Json, _] = try? @json.parse(source)
    match parsed {
      Ok(json) => get_endpoint(json, target, options~)
      Err(err) => Err(ParseError(err.to_string()))
    }
  }
}

///|
pub fn get_endpoint(
  document : Json,
  target : String,
  options~ : EndpointGetOptions,
) -> Result[EndpointSubset, ApispecError] {
  match normalize_document(document) {
    Err(err) => Err(err)
    Ok(document) => get_endpoint_normalized(document, target, options~)
  }
}

///|
fn get_endpoint_normalized(
  document : Json,
  target : String,
  options~ : EndpointGetOptions,
) -> Result[EndpointSubset, ApispecError] {
  match document {
    Object(root) =>
      match root.get("paths") {
        Some(Object(paths)) => {
          let candidates = collect_operation_candidates(paths)
          match resolve_operation(candidates, target) {
            Err(err) => Err(err)
            Ok(candidate) => {
              let ref_result = if options.no_resolve {
                Ok((None, []))
              } else {
                collect_reachable_components(document, candidate.operation)
              }
              match ref_result {
                Err(err) => Err(err)
                Ok((components, warnings)) =>
                  Ok({
                    openapi_version: openapi_version(root),
                    endpoint: candidate.endpoint,
                    operation: candidate.operation,
                    components,
                    warnings,
                  })
              }
            }
          }
        }
        Some(_) => Err(ParseError("expected 'paths' to be an object"))
        None => Err(ParseError("missing required 'paths' object"))
      }
    _ => Err(ParseError("expected JSON object input"))
  }
}

///|
fn openapi_version(root : Map[String, Json]) -> String {
  match root.get("openapi") {
    Some(String(version)) => version
    _ => "3.0.0"
  }
}

///|
fn collect_operation_candidates(
  paths : Map[String, Json],
) -> Array[OperationCandidate] {
  let candidates : Array[OperationCandidate] = []
  for path, path_item in paths {
    if path_item is Object(path_item_obj) {
      for method_name, operation_json in path_item_obj {
        let http_method = method_name.to_upper()
        if is_http_method(http_method) {
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
    let path_cmp = left.endpoint.path.lexical_compare(right.endpoint.path)
    if path_cmp != 0 {
      path_cmp
    } else {
      let method_cmp = method_rank(left.endpoint.http_method) -
        method_rank(right.endpoint.http_method)
      if method_cmp != 0 {
        method_cmp
      } else {
        left.endpoint.operation_id.lexical_compare(right.endpoint.operation_id)
      }
    }
  })
}

///|
fn resolve_operation(
  candidates : Array[OperationCandidate],
  target : String,
) -> Result[OperationCandidate, ApispecError] {
  let by_operation_id = candidates.filter(candidate => {
    candidate.endpoint.operation_id == target
  })
  if by_operation_id.length() == 1 {
    Ok(by_operation_id[0])
  } else if by_operation_id.length() > 1 {
    Err(AmbiguousMatch("operationId matched multiple operations: \{target}"))
  } else {
    match parse_method_path_target(target) {
      Some((http_method, path)) => {
        let by_method_path = candidates.filter(candidate => {
          candidate.endpoint.http_method.equal_ignore_ascii_case(http_method) &&
          candidate.endpoint.path == path
        })
        if by_method_path.length() == 1 {
          Ok(by_method_path[0])
        } else if by_method_path.length() > 1 {
          Err(AmbiguousMatch("target matched multiple operations: \{target}"))
        } else {
          resolve_by_path(candidates, target)
        }
      }
      None => resolve_by_path(candidates, target)
    }
  }
}

///|
fn resolve_by_path(
  candidates : Array[OperationCandidate],
  target : String,
) -> Result[OperationCandidate, ApispecError] {
  let by_path = candidates.filter(candidate => candidate.endpoint.path == target)
  if by_path.length() == 1 {
    Ok(by_path[0])
  } else if by_path.length() > 1 {
    Err(AmbiguousMatch("path matched multiple methods: \{target}"))
  } else {
    Err(ResourceNotFound("operation not found: \{target}"))
  }
}

///|
fn parse_method_path_target(target : String) -> (String, String)? {
  match target.trim().to_string().split_once(" ") {
    Some((method_view, path_view)) => {
      let http_method = method_view.to_string().to_upper()
      let path = path_view.trim().to_string()
      if is_http_method(http_method) && !path.is_empty() {
        Some((http_method, path))
      } else {
        None
      }
    }
    None => None
  }
}
