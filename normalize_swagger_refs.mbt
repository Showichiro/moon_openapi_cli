///|
fn rewrite_swagger_refs(value : Json) -> Json {
  match value {
    Object(object) => {
      let rewritten : Map[String, Json] = {}
      for key, child in object {
        if key == "$ref" {
          rewritten[key] = rewrite_swagger_ref_value(child)
        } else {
          rewritten[key] = rewrite_swagger_refs(child)
        }
      }
      Json::object(rewritten)
    }
    Array(items) => Json::array(items.map(rewrite_swagger_refs))
    _ => value
  }
}

///|
fn rewrite_swagger_ref_value(value : Json) -> Json {
  match value {
    String(ref_value) =>
      if ref_value.has_prefix("#/definitions/") {
        Json::string(
          "#/components/schemas/" +
          ref_value["#/definitions/".length():].to_string(),
        )
      } else {
        value
      }
    _ => value
  }
}
