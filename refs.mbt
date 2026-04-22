///|
priv struct RefCollection {
  components : Map[String, Map[String, Json]]
  warnings : Array[String]
  visited_internal : Map[String, Bool]
  warned_refs : Map[String, Bool]
}

///|
fn collect_reachable_components(
  document : Json,
  seed : Json,
) -> Result[(Json?, Array[String]), ApispecError] {
  let collection = new_ref_collection()
  match scan_refs(seed, document, collection) {
    Err(err) => Err(err)
    Ok(_) => Ok((components_to_json(collection), collection.warnings))
  }
}

///|
fn collect_schema_components(
  document : Json,
  name : String,
  schema : Json,
) -> Result[(Json?, Array[String]), ApispecError] {
  let collection = new_ref_collection()
  collection.visited_internal[component_key("schemas", name)] = true
  insert_component(collection, "schemas", name, schema)
  match scan_refs(schema, document, collection) {
    Err(err) => Err(err)
    Ok(_) => Ok((components_to_json(collection), collection.warnings))
  }
}

///|
fn new_ref_collection() -> RefCollection {
  let components : Map[String, Map[String, Json]] = {}
  let warnings : Array[String] = []
  let visited_internal : Map[String, Bool] = {}
  let warned_refs : Map[String, Bool] = {}
  RefCollection::{ components, warnings, visited_internal, warned_refs }
}

///|
fn scan_refs(
  value : Json,
  document : Json,
  collection : RefCollection,
) -> Result[Unit, ApispecError] {
  match value {
    Object(object) => {
      match object.get("$ref") {
        Some(String(ref_value)) =>
          match collect_ref(ref_value, document, collection) {
            Err(err) => return Err(err)
            Ok(_) => ()
          }
        _ => ()
      }
      for _, child in object {
        match scan_refs(child, document, collection) {
          Err(err) => return Err(err)
          Ok(_) => ()
        }
      }
      Ok(())
    }
    Array(items) => {
      for item in items {
        match scan_refs(item, document, collection) {
          Err(err) => return Err(err)
          Ok(_) => ()
        }
      }
      Ok(())
    }
    _ => Ok(())
  }
}

///|
fn collect_ref(
  ref_value : String,
  document : Json,
  collection : RefCollection,
) -> Result[Unit, ApispecError] {
  if !ref_value.has_prefix("#/") {
    warn_once(collection, ref_value, "unsupported external $ref: \{ref_value}")
    Ok(())
  } else {
    let tokens = @json_pointer.decode_ref(ref_value)
    if tokens.length() < 3 || tokens[0] != "components" {
      warn_once(
        collection,
        ref_value,
        "unsupported internal $ref: \{ref_value}",
      )
      Ok(())
    } else {
      let section = tokens[1]
      let name = tokens[2]
      match @json_pointer.get(document, tokens) {
        None => Err(ParseError("unresolved $ref: \{ref_value}"))
        Some(_) => {
          let key = component_key(section, name)
          if collection.visited_internal.contains(key) {
            Ok(())
          } else {
            let root_tokens : Array[String] = ["components", section, name]
            match @json_pointer.get(document, root_tokens) {
              None => Err(ParseError("unresolved $ref: \{ref_value}"))
              Some(component) => {
                collection.visited_internal[key] = true
                insert_component(collection, section, name, component)
                scan_refs(component, document, collection)
              }
            }
          }
        }
      }
    }
  }
}

///|
fn component_key(section : String, name : String) -> String {
  "\{section}/\{name}"
}

///|
fn insert_component(
  collection : RefCollection,
  section : String,
  name : String,
  component : Json,
) -> Unit {
  let section_map = collection.components.get_or_init(section, () => Map::new())
  section_map[name] = component
}

///|
fn warn_once(
  collection : RefCollection,
  ref_value : String,
  message : String,
) -> Unit {
  if !collection.warned_refs.contains(ref_value) {
    collection.warned_refs[ref_value] = true
    collection.warnings.push(message)
  }
}

///|
fn components_to_json(collection : RefCollection) -> Json? {
  if collection.components.is_empty() {
    None
  } else {
    let components : Map[String, Json] = {}
    for section, values in collection.components {
      components[section] = Json::object(values)
    }
    Some(Json::object(components))
  }
}
