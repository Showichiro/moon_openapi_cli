///|
using @errors {type ApispecError}

///|
pub fn parse_json_object_source(source : String) -> Result[Json, ApispecError] {
  let trimmed = source.trim_start()
  if !trimmed.has_prefix("{") {
    Err(ApispecError::ParseError("expected JSON object input"))
  } else {
    let parsed : Result[Json, _] = try? @json.parse(source)
    match parsed {
      Ok(json) => Ok(json)
      Err(err) => Err(ApispecError::ParseError(err.to_string()))
    }
  }
}
