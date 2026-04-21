///|
const DEFAULT_JSON_MEDIA_TYPE : String = "application/json"

///|
fn normalize_document(document : Json) -> Result[Json, ApispecError] {
  match document {
    Object(root) =>
      match root.get("openapi") {
        Some(String(version)) =>
          if version.has_prefix("3.") {
            Ok(document)
          } else {
            Err(UnsupportedSpec("unsupported OpenAPI version: \{version}"))
          }
        Some(_) => Err(ParseError("expected 'openapi' to be a string"))
        None =>
          match root.get("swagger") {
            Some(String(version)) =>
              if version == "2.0" {
                normalize_swagger2(root)
              } else {
                Err(UnsupportedSpec("unsupported Swagger version: \{version}"))
              }
            Some(_) => Err(ParseError("expected 'swagger' to be a string"))
            None => Err(ParseError("missing required 'openapi' version"))
          }
      }
    _ => Err(ParseError("expected JSON object input"))
  }
}

///|
fn normalize_swagger2(root : Map[String, Json]) -> Result[Json, ApispecError] {
  let normalized : Map[String, Json] = { "openapi": Json::string("3.0.0") }
  if root.get("info") is Some(info) {
    normalized["info"] = rewrite_swagger_refs(info)
  }
  match root.get("paths") {
    Some(Object(paths)) =>
      match normalize_swagger_paths(root, paths) {
        Err(err) => return Err(err)
        Ok(paths) => normalized["paths"] = paths
      }
    Some(_) => return Err(ParseError("expected 'paths' to be an object"))
    None => return Err(ParseError("missing required 'paths' object"))
  }
  let components = normalize_swagger_components(root)
  if !components.is_empty() {
    normalized["components"] = Json::object(components)
  }
  Ok(Json::object(normalized))
}

///|
fn normalize_swagger_components(root : Map[String, Json]) -> Map[String, Json] {
  let components : Map[String, Json] = {}
  if root.get("definitions") is Some(Object(definitions)) {
    let schemas : Map[String, Json] = {}
    for name, schema in definitions {
      schemas[name] = rewrite_swagger_refs(schema)
    }
    components["schemas"] = Json::object(schemas)
  }
  components
}

///|
fn normalize_swagger_paths(
  root : Map[String, Json],
  paths : Map[String, Json],
) -> Result[Json, ApispecError] {
  let normalized_paths : Map[String, Json] = {}
  for path, path_item in paths {
    match path_item {
      Object(path_item_object) => {
        let normalized_path_item : Map[String, Json] = {}
        let path_parameters = match
          extract_parameter_array(path_item_object, "path") {
          Err(err) => return Err(err)
          Ok(parameters) => parameters
        }
        for method_name, operation_json in path_item_object {
          let http_method = method_name.to_upper()
          if is_http_method(http_method) {
            match operation_json {
              Object(operation) =>
                match
                  normalize_swagger_operation(root, operation, path_parameters) {
                  Err(err) => return Err(err)
                  Ok(normalized_operation) =>
                    normalized_path_item[method_name] = normalized_operation
                }
              _ => ()
            }
          }
        }
        normalized_paths[path] = Json::object(normalized_path_item)
      }
      _ => ()
    }
  }
  Ok(Json::object(normalized_paths))
}

///|
fn normalize_swagger_operation(
  root : Map[String, Json],
  operation : Map[String, Json],
  path_parameters : Array[Json],
) -> Result[Json, ApispecError] {
  let normalized : Map[String, Json] = {}
  for key, value in operation {
    if key != "parameters" &&
      key != "responses" &&
      key != "consumes" &&
      key != "produces" {
      normalized[key] = rewrite_swagger_refs(value)
    }
  }
  let combined_parameters = path_parameters.copy()
  match operation.get("parameters") {
    Some(Array(parameters)) =>
      for parameter in parameters {
        combined_parameters.push(parameter)
      }
    Some(_) =>
      return Err(ParseError("expected operation 'parameters' to be an array"))
    None => ()
  }
  match normalize_swagger_parameters(root, operation, combined_parameters) {
    Err(err) => return Err(err)
    Ok((parameters, request_body)) => {
      if parameters.length() > 0 {
        normalized["parameters"] = Json::array(parameters)
      }
      if request_body is Some(body) {
        normalized["requestBody"] = body
      }
    }
  }
  match operation.get("responses") {
    Some(Object(responses)) =>
      normalized["responses"] = normalize_swagger_responses(
        root, operation, responses,
      )
    Some(_) =>
      return Err(ParseError("expected operation 'responses' to be an object"))
    None => ()
  }
  Ok(Json::object(normalized))
}

///|
fn extract_parameter_array(
  object : Map[String, Json],
  label : String,
) -> Result[Array[Json], ApispecError] {
  match object.get("parameters") {
    Some(Array(parameters)) => Ok(parameters)
    Some(_) => Err(ParseError("expected \{label} 'parameters' to be an array"))
    None => Ok([])
  }
}

///|
fn normalize_swagger_parameters(
  root : Map[String, Json],
  operation : Map[String, Json],
  parameters : Array[Json],
) -> Result[(Array[Json], Json?), ApispecError] {
  let regular_parameters : Array[Json] = []
  let body_parameters : Array[Json] = []
  for parameter in parameters {
    match parameter {
      Object(parameter_object) =>
        match parameter_object.get("in") {
          Some(String("body")) => body_parameters.push(parameter)
          _ => regular_parameters.push(rewrite_swagger_refs(parameter))
        }
      _ => regular_parameters.push(rewrite_swagger_refs(parameter))
    }
  }
  if body_parameters.length() > 1 {
    Err(ParseError("multiple body parameters are not supported"))
  } else if body_parameters.length() == 1 {
    match normalize_swagger_request_body(root, operation, body_parameters[0]) {
      Err(err) => Err(err)
      Ok(body) => Ok((regular_parameters, Some(body)))
    }
  } else {
    Ok((regular_parameters, None))
  }
}

///|
fn normalize_swagger_request_body(
  root : Map[String, Json],
  operation : Map[String, Json],
  body_parameter : Json,
) -> Result[Json, ApispecError] {
  match body_parameter {
    Object(parameter) =>
      match parameter.get("schema") {
        None => Err(ParseError("expected body parameter 'schema'"))
        Some(schema) => {
          let media_type = swagger_media_type(root, operation, "consumes")
          let media_object : Map[String, Json] = {
            "schema": rewrite_swagger_refs(schema),
          }
          let content : Map[String, Json] = {}
          content[media_type] = Json::object(media_object)
          let request_body : Map[String, Json] = {
            "content": Json::object(content),
          }
          if parameter.get("description") is Some(description) {
            request_body["description"] = rewrite_swagger_refs(description)
          }
          match parameter.get("required") {
            Some(True) => request_body["required"] = Json::boolean(true)
            Some(False) => request_body["required"] = Json::boolean(false)
            _ => ()
          }
          Ok(Json::object(request_body))
        }
      }
    _ => Err(ParseError("expected body parameter to be an object"))
  }
}

///|
fn normalize_swagger_responses(
  root : Map[String, Json],
  operation : Map[String, Json],
  responses : Map[String, Json],
) -> Json {
  let normalized_responses : Map[String, Json] = {}
  for code, response in responses {
    normalized_responses[code] = normalize_swagger_response(
      root, operation, response,
    )
  }
  Json::object(normalized_responses)
}

///|
fn normalize_swagger_response(
  root : Map[String, Json],
  operation : Map[String, Json],
  response : Json,
) -> Json {
  match response {
    Object(response_object) => {
      let normalized_response : Map[String, Json] = {}
      for key, value in response_object {
        if key != "schema" {
          normalized_response[key] = rewrite_swagger_refs(value)
        }
      }
      if response_object.get("schema") is Some(schema) {
        let media_type = swagger_media_type(root, operation, "produces")
        let media_object : Map[String, Json] = {
          "schema": rewrite_swagger_refs(schema),
        }
        let content : Map[String, Json] = {}
        content[media_type] = Json::object(media_object)
        normalized_response["content"] = Json::object(content)
      }
      Json::object(normalized_response)
    }
    _ => rewrite_swagger_refs(response)
  }
}

///|
fn swagger_media_type(
  root : Map[String, Json],
  operation : Map[String, Json],
  key : String,
) -> String {
  match first_string_in_array(operation, key) {
    Some(media_type) => media_type
    None =>
      match first_string_in_array(root, key) {
        Some(media_type) => media_type
        None => DEFAULT_JSON_MEDIA_TYPE
      }
  }
}

///|
fn first_string_in_array(object : Map[String, Json], key : String) -> String? {
  match object.get(key) {
    Some(Array(values)) =>
      if values.length() > 0 {
        match values[0] {
          String(value) => Some(value)
          _ => None
        }
      } else {
        None
      }
    _ => None
  }
}

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
