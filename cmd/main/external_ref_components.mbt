///|
fn external_ref_target(
  tokens : Array[String],
  root_kind : RootSpecKind,
) -> ExternalRefTarget? {
  if tokens.length() >= 3 && tokens[0] == "components" {
    let section = tokens[1]
    let name = tokens[2]
    Some({
      import_tokens: ["components", section, name],
      insert_container: "components",
      section,
      name,
      internal_ref: encode_internal_ref(tokens),
    })
  } else if tokens.length() >= 2 && tokens[0] == "definitions" {
    let name = tokens[1]
    match root_kind {
      RootSwagger2 =>
        Some({
          import_tokens: ["definitions", name],
          insert_container: "definitions",
          section: "schemas",
          name,
          internal_ref: encode_internal_ref(tokens),
        })
      RootOpenApi => {
        let rewritten_tokens : Array[String] = ["components", "schemas", name]
        for token in tokens[2:] {
          rewritten_tokens.push(token)
        }
        Some({
          import_tokens: ["definitions", name],
          insert_container: "components",
          section: "schemas",
          name,
          internal_ref: encode_internal_ref(rewritten_tokens),
        })
      }
    }
  } else {
    None
  }
}

///|
fn encode_internal_ref(tokens : Array[String]) -> String {
  @json_pointer.encode_ref(tokens)
}

///|
fn root_component(
  root : Map[String, Json],
  target : ExternalRefTarget,
) -> Json? {
  match target.insert_container {
    "definitions" =>
      match root.get("definitions") {
        Some(Object(definitions)) => definitions.get(target.name)
        _ => None
      }
    _ =>
      match root.get("components") {
        Some(Object(components)) =>
          match components.get(target.section) {
            Some(Object(section)) => section.get(target.name)
            _ => None
          }
        _ => None
      }
  }
}

///|
fn insert_root_component(
  root : Map[String, Json],
  target : ExternalRefTarget,
  component : Json,
) -> Bool {
  match target.insert_container {
    "definitions" =>
      match ensure_object_property(root, "definitions") {
        None => false
        Some(definitions) => {
          definitions[target.name] = component
          true
        }
      }
    _ =>
      match ensure_object_property(root, "components") {
        None => false
        Some(components) =>
          match ensure_object_property(components, target.section) {
            None => false
            Some(section) => {
              section[target.name] = component
              true
            }
          }
      }
  }
}

///|
fn ensure_object_property(
  object : Map[String, Json],
  key : String,
) -> Map[String, Json]? {
  match object.get(key) {
    Some(Object(child)) => Some(child)
    Some(_) => None
    None => {
      let child : Map[String, Json] = {}
      object[key] = Json::object(child)
      Some(child)
    }
  }
}

///|
fn replace_refs_in_place(value : Json, rewrites : Map[String, String]) -> Unit {
  match value {
    Object(object) => {
      match object.get("$ref") {
        Some(String(ref_value)) =>
          match rewrites.get(ref_value) {
            Some(internal_ref) => object["$ref"] = Json::string(internal_ref)
            None => ()
          }
        _ => ()
      }
      for _, child in object {
        replace_refs_in_place(child, rewrites)
      }
    }
    Array(items) =>
      for item in items {
        replace_refs_in_place(item, rewrites)
      }
    _ => ()
  }
}
