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
