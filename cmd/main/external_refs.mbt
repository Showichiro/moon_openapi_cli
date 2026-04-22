///|
async fn resolve_endpoint_with_external_refs(
  source : String,
  input : String,
  target : String,
  options : @lib.EndpointGetOptions,
) -> Result[ResolvedExtraction[@lib.EndpointSubset], @lib.ApispecError] {
  if options.no_resolve {
    get_endpoint_extraction(source, target, options)
  } else {
    resolve_external_refs(source, input, current => {
      get_endpoint_extraction(current, target, options)
    })
  }
}

///|
async fn resolve_schema_with_external_refs(
  source : String,
  input : String,
  name : String,
  options : @lib.SchemaGetOptions,
) -> Result[ResolvedExtraction[@lib.SchemaSubset], @lib.ApispecError] {
  resolve_external_refs(source, input, current => {
    get_schema_extraction(current, name, options)
  })
}

///|
fn get_endpoint_extraction(
  source : String,
  target : String,
  options : @lib.EndpointGetOptions,
) -> Result[ResolvedExtraction[@lib.EndpointSubset], @lib.ApispecError] {
  match @lib.get_endpoint_from_source(source, target, options~) {
    Err(err) => Err(err)
    Ok(subset) => Ok({ subset, warnings: subset.warnings })
  }
}

///|
fn get_schema_extraction(
  source : String,
  name : String,
  options : @lib.SchemaGetOptions,
) -> Result[ResolvedExtraction[@lib.SchemaSubset], @lib.ApispecError] {
  match @lib.get_schema_from_source(source, name, options~) {
    Err(err) => Err(err)
    Ok(subset) => Ok({ subset, warnings: subset.warnings })
  }
}

///|
async fn[Subset] resolve_external_refs(
  source : String,
  input : String,
  extract : (String) -> Result[ResolvedExtraction[Subset], @lib.ApispecError],
) -> Result[ResolvedExtraction[Subset], @lib.ApispecError] {
  let location = ref_location_from_input(input)
  let accumulated : Array[String] = []
  let blocked : Map[String, Bool] = {}
  let mut current = source
  for _ in 0..<EXTERNAL_REF_MAX_PASSES {
    match extract(current) {
      Err(err) => return Err(err)
      Ok(result) =>
        match
          advance_external_ref_resolution(
            current,
            location,
            result.warnings,
            accumulated,
            blocked,
          ) {
          ExternalRefsRewritten(source) => current = source
          ExternalRefsResolved | ExternalRefsUnchanged =>
            return Ok({
              subset: result.subset,
              warnings: merge_cli_warnings(accumulated, result.warnings),
            })
        }
    }
  }
  match extract(current) {
    Err(err) => Err(err)
    Ok(result) => {
      accumulated.push(
        "external $ref resolution stopped: maximum pass count reached",
      )
      Ok({
        subset: result.subset,
        warnings: merge_cli_warnings(accumulated, result.warnings),
      })
    }
  }
}
