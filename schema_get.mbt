///|
fn get_schema_normalized(
  document : Json,
  name : String,
  options~ : SchemaGetOptions,
) -> Result[SchemaSubset, ApispecError] {
  match document {
    Object(root) =>
      match extract_schema_map(root) {
        Err(err) => Err(err)
        Ok(schemas) =>
          match schemas.get(name) {
            None => Err(ResourceNotFound("schema not found: \{name}"))
            Some(schema) =>
              match @refs.collect_schema_components(document, name, schema) {
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
    _ => Err(ParseError("expected JSON object input"))
  }
}
