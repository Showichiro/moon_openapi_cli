///|
fn collect_schema_usages(
  document : Json,
  root : Map[String, Json],
  name : String,
) -> Result[(Array[EndpointSummary], Array[String]), ApispecError] {
  match root.get("paths") {
    None => Ok(([], []))
    Some(Object(paths)) => {
      let usages : Array[EndpointSummary] = []
      let warnings : Array[String] = []
      let candidates = collect_operation_candidates(paths)
      for candidate in candidates {
        match collect_reachable_components(document, candidate.operation) {
          Err(err) => return Err(err)
          Ok((components, operation_warnings)) =>
            if reachable_components_contain_schema(components, name) {
              usages.push(candidate.endpoint)
              append_warnings(warnings, operation_warnings)
            }
        }
      }
      Ok((usages, warnings))
    }
    Some(_) => Err(ParseError("expected 'paths' to be an object"))
  }
}

///|
fn reachable_components_contain_schema(
  components : Json?,
  name : String,
) -> Bool {
  match components {
    Some(Object(component_root)) =>
      match component_root.get("schemas") {
        Some(Object(schemas)) => schemas.contains(name)
        _ => false
      }
    _ => false
  }
}

///|
fn merge_warnings(left : Array[String], right : Array[String]) -> Array[String] {
  let merged : Array[String] = []
  append_warnings(merged, left)
  append_warnings(merged, right)
  merged
}

///|
fn append_warnings(target : Array[String], warnings : Array[String]) -> Unit {
  for warning in warnings {
    if !target.contains(warning) {
      target.push(warning)
    }
  }
}
