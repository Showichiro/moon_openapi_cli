///|
async fn resolve_endpoint_with_external_refs(
  source : String,
  input : String,
  target : String,
  options : @lib.EndpointGetOptions,
) -> Result[ResolvedEndpointExtraction, @lib.ApispecError] {
  if options.no_resolve {
    match @lib.get_endpoint_from_source(source, target, options~) {
      Err(err) => Err(err)
      Ok(subset) => Ok({ subset, warnings: subset.warnings })
    }
  } else {
    let location = ref_location_from_input(input)
    let accumulated : Array[String] = []
    let blocked : Map[String, Bool] = {}
    let mut current = source
    for _ in 0..<EXTERNAL_REF_MAX_PASSES {
      match @lib.get_endpoint_from_source(current, target, options~) {
        Err(err) => return Err(err)
        Ok(subset) =>
          match
            advance_external_ref_resolution(
              current,
              location,
              subset.warnings,
              accumulated,
              blocked,
            ) {
            ExternalRefsRewritten(source) => current = source
            ExternalRefsResolved | ExternalRefsUnchanged =>
              return Ok({
                subset,
                warnings: merge_cli_warnings(accumulated, subset.warnings),
              })
          }
      }
    }
    match @lib.get_endpoint_from_source(current, target, options~) {
      Err(err) => Err(err)
      Ok(subset) => {
        accumulated.push(
          "external $ref resolution stopped: maximum pass count reached",
        )
        Ok({
          subset,
          warnings: merge_cli_warnings(accumulated, subset.warnings),
        })
      }
    }
  }
}

///|
async fn resolve_schema_with_external_refs(
  source : String,
  input : String,
  name : String,
  options : @lib.SchemaGetOptions,
) -> Result[ResolvedSchemaExtraction, @lib.ApispecError] {
  let location = ref_location_from_input(input)
  let accumulated : Array[String] = []
  let blocked : Map[String, Bool] = {}
  let mut current = source
  for _ in 0..<EXTERNAL_REF_MAX_PASSES {
    match @lib.get_schema_from_source(current, name, options~) {
      Err(err) => return Err(err)
      Ok(subset) =>
        match
          advance_external_ref_resolution(
            current,
            location,
            subset.warnings,
            accumulated,
            blocked,
          ) {
          ExternalRefsRewritten(source) => current = source
          ExternalRefsResolved | ExternalRefsUnchanged =>
            return Ok({
              subset,
              warnings: merge_cli_warnings(accumulated, subset.warnings),
            })
        }
    }
  }
  match @lib.get_schema_from_source(current, name, options~) {
    Err(err) => Err(err)
    Ok(subset) => {
      accumulated.push(
        "external $ref resolution stopped: maximum pass count reached",
      )
      Ok({ subset, warnings: merge_cli_warnings(accumulated, subset.warnings) })
    }
  }
}
