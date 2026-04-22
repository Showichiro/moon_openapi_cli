///|
fn object_schema(
  properties : Map[String, Json],
  required : Array[String],
) -> Json {
  let schema : Map[String, Json] = {
    "type": Json::string("object"),
    "properties": Json::object(properties),
    "additionalProperties": Json::boolean(false),
  }
  if required.length() > 0 {
    schema["required"] = Json::array(required.map(name => Json::string(name)))
  }
  Json::object(schema)
}

///|
fn array_schema(items : Json) -> Json {
  { "type": Json::string("array"), "items": items }
}

///|
fn string_schema(description : String) -> Json {
  { "type": Json::string("string"), "description": Json::string(description) }
}

///|
fn boolean_schema(description : String) -> Json {
  { "type": Json::string("boolean"), "description": Json::string(description) }
}

///|
fn integer_schema(description : String) -> Json {
  { "type": Json::string("integer"), "description": Json::string(description) }
}

///|
fn enum_schema(description : String, values : Array[String]) -> Json {
  let schema : Map[String, Json] = {
    "type": Json::string("string"),
    "description": Json::string(description),
    "enum": Json::array(values.map(value => Json::string(value))),
  }
  Json::object(schema)
}

///|
fn json_schema(description : String) -> Json {
  { "description": Json::string(description) }
}
