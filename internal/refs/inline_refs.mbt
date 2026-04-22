///|
pub fn inline_internal_refs(document : Json, seed : Json) -> Json {
  let visiting : Map[String, Bool] = {}
  inline_json_value(seed, document, visiting)
}

///|
fn inline_json_value(
  value : Json,
  document : Json,
  visiting : Map[String, Bool],
) -> Json {
  match value {
    Object(object) =>
      match object.get("$ref") {
        Some(String(ref_value)) =>
          inline_ref_object(ref_value, object, document, visiting)
        _ => inline_object_children(object, document, visiting)
      }
    Array(items) => {
      let rewritten : Array[Json] = []
      for item in items {
        rewritten.push(inline_json_value(item, document, visiting))
      }
      Json::array(rewritten)
    }
    _ => value
  }
}

///|
fn inline_ref_object(
  ref_value : String,
  object : Map[String, Json],
  document : Json,
  visiting : Map[String, Bool],
) -> Json {
  if !ref_value.has_prefix("#/") || visiting.contains(ref_value) {
    inline_object_without_ref_expansion(object, document, visiting)
  } else {
    let tokens = @json_pointer.decode_ref(ref_value)
    if !is_component_ref(tokens) {
      inline_object_without_ref_expansion(object, document, visiting)
    } else {
      match @json_pointer.get(document, tokens) {
        None => inline_object_without_ref_expansion(object, document, visiting)
        Some(target) => {
          visiting[ref_value] = true
          let expanded = inline_json_value(target, document, visiting)
          visiting.remove(ref_value)
          merge_ref_siblings(expanded, object, document, visiting)
        }
      }
    }
  }
}

///|
fn is_component_ref(tokens : Array[String]) -> Bool {
  tokens.length() >= 3 && tokens[0] == "components"
}

///|
fn inline_object_children(
  object : Map[String, Json],
  document : Json,
  visiting : Map[String, Bool],
) -> Json {
  let rewritten : Map[String, Json] = {}
  for key, child in object {
    rewritten[key] = inline_json_value(child, document, visiting)
  }
  Json::object(rewritten)
}

///|
fn inline_object_without_ref_expansion(
  object : Map[String, Json],
  document : Json,
  visiting : Map[String, Bool],
) -> Json {
  let rewritten : Map[String, Json] = {}
  for key, child in object {
    rewritten[key] = if key == "$ref" {
      child
    } else {
      inline_json_value(child, document, visiting)
    }
  }
  Json::object(rewritten)
}

///|
fn merge_ref_siblings(
  expanded : Json,
  object : Map[String, Json],
  document : Json,
  visiting : Map[String, Bool],
) -> Json {
  if object.length() == 1 {
    expanded
  } else {
    match expanded {
      Object(expanded_object) => {
        let merged : Map[String, Json] = {}
        for key, child in expanded_object {
          merged[key] = child
        }
        for key, child in object {
          if key != "$ref" {
            merged[key] = inline_json_value(child, document, visiting)
          }
        }
        Json::object(merged)
      }
      _ => expanded
    }
  }
}
