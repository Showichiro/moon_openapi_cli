///|
pub fn schema_get_options(with_usages : Bool) -> SchemaGetOptions {
  { with_usages, }
}

///|
pub fn list_schemas_from_source(
  source : String,
) -> Result[Array[SchemaSummary], ApispecError] {
  let trimmed = source.trim_start()
  if !trimmed.has_prefix("{") {
    Err(ParseError("expected JSON object input"))
  } else {
    let parsed : Result[Json, _] = try? @json.parse(source)
    match parsed {
      Ok(json) => list_schemas(json)
      Err(err) => Err(ParseError(err.to_string()))
    }
  }
}

///|
pub fn list_schemas(
  document : Json,
) -> Result[Array[SchemaSummary], ApispecError] {
  match document {
    Object(root) =>
      match validate_openapi3(root) {
        Err(err) => Err(err)
        Ok(_) =>
          match extract_schema_map(root) {
            Err(err) => Err(err)
            Ok(schemas) => Ok(extract_schema_summaries(schemas))
          }
      }
    _ => Err(ParseError("expected JSON object input"))
  }
}

///|
pub fn get_schema_from_source(
  source : String,
  name : String,
  options~ : SchemaGetOptions,
) -> Result[SchemaSubset, ApispecError] {
  let trimmed = source.trim_start()
  if !trimmed.has_prefix("{") {
    Err(ParseError("expected JSON object input"))
  } else {
    let parsed : Result[Json, _] = try? @json.parse(source)
    match parsed {
      Ok(json) => get_schema(json, name, options~)
      Err(err) => Err(ParseError(err.to_string()))
    }
  }
}

///|
pub fn get_schema(
  document : Json,
  name : String,
  options~ : SchemaGetOptions,
) -> Result[SchemaSubset, ApispecError] {
  match document {
    Object(root) =>
      match validate_openapi3(root) {
        Err(err) => Err(err)
        Ok(_) =>
          match extract_schema_map(root) {
            Err(err) => Err(err)
            Ok(schemas) =>
              match schemas.get(name) {
                None => Err(ResourceNotFound("schema not found: \{name}"))
                Some(schema) =>
                  match collect_schema_components(document, name, schema) {
                    Err(err) => Err(err)
                    Ok((components, warnings)) => {
                      let usage_result = if options.with_usages {
                        match collect_schema_usages(document, root, name) {
                          Err(err) => Err(err)
                          Ok((usages, usage_warnings)) =>
                            Ok((Some(usages), usage_warnings))
                        }
                      } else {
                        Ok((None, []))
                      }
                      match usage_result {
                        Err(err) => Err(err)
                        Ok((usages, usage_warnings)) =>
                          Ok({
                            openapi_version: openapi_version(root),
                            name,
                            schema,
                            components,
                            usages,
                            warnings: merge_warnings(warnings, usage_warnings),
                          })
                      }
                    }
                  }
              }
          }
      }
    _ => Err(ParseError("expected JSON object input"))
  }
}

///|
fn extract_schema_map(
  root : Map[String, Json],
) -> Result[Map[String, Json], ApispecError] {
  match root.get("components") {
    None => Ok({})
    Some(Object(components)) =>
      match components.get("schemas") {
        None => Ok({})
        Some(Object(schemas)) => Ok(schemas)
        Some(_) =>
          Err(ParseError("expected 'components.schemas' to be an object"))
      }
    Some(_) => Err(ParseError("expected 'components' to be an object"))
  }
}

///|
fn extract_schema_summaries(
  schemas : Map[String, Json],
) -> Array[SchemaSummary] {
  let summaries : Array[SchemaSummary] = []
  for name, schema in schemas {
    summaries.push(schema_summary(name, schema))
  }
  sort_schema_summaries(summaries)
  summaries
}

///|
fn schema_summary(name : String, schema : Json) -> SchemaSummary {
  match schema {
    Object(object) => {
      let title = match object.get("title") {
        Some(String(value)) => Some(value)
        _ => None
      }
      let schema_type = match object.get("type") {
        Some(String(value)) => Some(value)
        _ => None
      }
      { name, title, schema_type }
    }
    _ => { name, title: None, schema_type: None }
  }
}

///|
fn sort_schema_summaries(summaries : Array[SchemaSummary]) -> Unit {
  summaries.sort_by((left, right) => left.name.lexical_compare(right.name))
}

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
