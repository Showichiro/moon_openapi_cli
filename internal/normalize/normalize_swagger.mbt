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
    Some(_) =>
      return Err(ApispecError::ParseError("expected 'paths' to be an object"))
    None =>
      return Err(ApispecError::ParseError("missing required 'paths' object"))
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
          if @http_method.is_http_method(http_method) {
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
      return Err(
        ApispecError::ParseError(
          "expected operation 'parameters' to be an array",
        ),
      )
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
      return Err(
        ApispecError::ParseError(
          "expected operation 'responses' to be an object",
        ),
      )
    None => ()
  }
  Ok(Json::object(normalized))
}
