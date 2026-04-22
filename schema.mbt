///|
pub fn schema_get_options(with_usages : Bool) -> SchemaGetOptions {
  { with_usages, }
}

///|
pub fn list_schemas_from_source(
  source : String,
) -> Result[Array[SchemaSummary], ApispecError] {
  match parse_json_object_source(source) {
    Ok(json) => list_schemas(json)
    Err(err) => Err(err)
  }
}

///|
pub fn list_schemas(
  document : Json,
) -> Result[Array[SchemaSummary], ApispecError] {
  match normalize_document(document) {
    Err(err) => Err(err)
    Ok(document) => list_schemas_normalized(document)
  }
}

///|
pub fn get_schema_from_source(
  source : String,
  name : String,
  options~ : SchemaGetOptions,
) -> Result[SchemaSubset, ApispecError] {
  match parse_json_object_source(source) {
    Ok(json) => get_schema(json, name, options~)
    Err(err) => Err(err)
  }
}

///|
pub fn get_schema(
  document : Json,
  name : String,
  options~ : SchemaGetOptions,
) -> Result[SchemaSubset, ApispecError] {
  match normalize_document(document) {
    Err(err) => Err(err)
    Ok(document) => get_schema_normalized(document, name, options~)
  }
}
