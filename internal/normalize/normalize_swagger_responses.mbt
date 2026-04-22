///|
const DEFAULT_JSON_MEDIA_TYPE : String = "application/json"

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
