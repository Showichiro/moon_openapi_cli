///|
using @errors {type ApispecError}

///|
pub fn extract_schema_map(
  root : Map[String, Json],
) -> Result[Map[String, Json], ApispecError] {
  match root.get("components") {
    None => Ok({})
    Some(Object(components)) =>
      match components.get("schemas") {
        None => Ok({})
        Some(Object(schemas)) => Ok(schemas)
        Some(_) =>
          Err(
            ApispecError::ParseError(
              "expected 'components.schemas' to be an object",
            ),
          )
      }
    Some(_) =>
      Err(ApispecError::ParseError("expected 'components' to be an object"))
  }
}
