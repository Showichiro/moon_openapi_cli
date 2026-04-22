///|
fn list_schemas_normalized(
  document : Json,
) -> Result[Array[SchemaSummary], ApispecError] {
  match document {
    Object(root) =>
      match extract_schema_map(root) {
        Err(err) => Err(err)
        Ok(schemas) => Ok(extract_schema_summaries(schemas))
      }
    _ => Err(ParseError("expected JSON object input"))
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
fn sort_schema_summaries(summaries : Array[SchemaSummary]) -> Unit {
  summaries.sort_by((left, right) => left.name.lexical_compare(right.name))
}
