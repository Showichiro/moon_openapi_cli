///|
using @errors {type ApispecError}

///|
pub fn normalize_document(document : Json) -> Result[Json, ApispecError] {
  match document {
    Object(root) =>
      match root.get("openapi") {
        Some(String(version)) =>
          if version.has_prefix("3.") {
            Ok(document)
          } else {
            Err(
              ApispecError::UnsupportedSpec(
                "unsupported OpenAPI version: \{version}",
              ),
            )
          }
        Some(_) =>
          Err(ApispecError::ParseError("expected 'openapi' to be a string"))
        None =>
          match root.get("swagger") {
            Some(String(version)) =>
              if version == "2.0" {
                normalize_swagger2(root)
              } else {
                Err(
                  ApispecError::UnsupportedSpec(
                    "unsupported Swagger version: \{version}",
                  ),
                )
              }
            Some(_) =>
              Err(ApispecError::ParseError("expected 'swagger' to be a string"))
            None =>
              Err(
                ApispecError::ParseError("missing required 'openapi' version"),
              )
          }
      }
    _ => Err(ApispecError::ParseError("expected JSON object input"))
  }
}
