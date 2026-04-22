///|
pub fn endpoint_get_options(no_resolve : Bool) -> EndpointGetOptions {
  { no_resolve, }
}

///|
pub fn get_endpoint_from_source(
  source : String,
  target : String,
  options~ : EndpointGetOptions,
) -> Result[EndpointSubset, ApispecError] {
  match @source.parse_json_object_source(source) {
    Ok(json) => get_endpoint(json, target, options~)
    Err(err) => Err(err)
  }
}

///|
pub fn get_endpoint(
  document : Json,
  target : String,
  options~ : EndpointGetOptions,
) -> Result[EndpointSubset, ApispecError] {
  match @normalize.normalize_document(document) {
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
                @refs.collect_reachable_components(
                  document,
                  candidate.operation,
                )
              }
              match ref_result {
                Err(err) => Err(err)
                Ok((components, warnings)) =>
                  Ok({
                    openapi_version: @openapi_metadata.openapi_version(root),
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
      if @http_method.is_http_method(http_method) && !path.is_empty() {
        Some((http_method, path))
      } else {
        None
      }
    }
    None => None
  }
}
