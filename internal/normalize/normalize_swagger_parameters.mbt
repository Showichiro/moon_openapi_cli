///|
fn extract_parameter_array(
  object : Map[String, Json],
  label : String,
) -> Result[Array[Json], ApispecError] {
  match object.get("parameters") {
    Some(Array(parameters)) => Ok(parameters)
    Some(_) =>
      Err(
        ApispecError::ParseError(
          "expected \{label} 'parameters' to be an array",
        ),
      )
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
    Err(ApispecError::ParseError("multiple body parameters are not supported"))
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
        None =>
          Err(ApispecError::ParseError("expected body parameter 'schema'"))
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
    _ =>
      Err(ApispecError::ParseError("expected body parameter to be an object"))
  }
}
