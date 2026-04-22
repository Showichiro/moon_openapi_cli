///|
fn normalize_document(document : Json) -> Result[Json, ApispecError] {
  match document {
    Object(root) =>
      match root.get("openapi") {
        Some(String(version)) =>
          if version.has_prefix("3.") {
            Ok(document)
          } else {
            Err(UnsupportedSpec("unsupported OpenAPI version: \{version}"))
          }
        Some(_) => Err(ParseError("expected 'openapi' to be a string"))
        None =>
          match root.get("swagger") {
            Some(String(version)) =>
              if version == "2.0" {
                normalize_swagger2(root)
              } else {
                Err(UnsupportedSpec("unsupported Swagger version: \{version}"))
              }
            Some(_) => Err(ParseError("expected 'swagger' to be a string"))
            None => Err(ParseError("missing required 'openapi' version"))
          }
      }
    _ => Err(ParseError("expected JSON object input"))
  }
}
