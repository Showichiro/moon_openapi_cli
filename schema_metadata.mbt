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
