///|
pub fn EndpointSummary::to_json(self : EndpointSummary) -> Json {
  let tags_json = self.tags.map(tag => Json::string(tag))
  let object : Map[String, Json] = {
    "operationId": Json::string(self.operation_id),
    "method": Json::string(self.http_method),
    "path": Json::string(self.path),
    "tags": Json::array(tags_json),
  }
  if self.summary is Some(summary) {
    object["summary"] = Json::string(summary)
  }
  Json::object(object)
}

///|
pub fn format_endpoint_list(
  endpoints : Array[EndpointSummary],
  format : EndpointListFormat,
) -> String {
  match format {
    JsonLines =>
      endpoints.map(endpoint => endpoint.to_json().stringify()).join("\n")
    Markdown => endpoints.map(endpoint_to_markdown_line).join("\n")
    Quiet => endpoints.map(endpoint => endpoint.operation_id).join("\n")
  }
}

///|
fn endpoint_to_markdown_line(endpoint : EndpointSummary) -> String {
  let base = "- \{endpoint.http_method} \{endpoint.path} \{endpoint.operation_id}"
  match endpoint.summary {
    Some(summary) => "\{base} - \{summary}"
    None => base
  }
}

///|
pub fn EndpointSubset::to_json(self : EndpointSubset) -> Json {
  let operation_by_method : Map[String, Json] = {}
  operation_by_method[self.endpoint.http_method.to_lower()] = self.operation
  let paths : Map[String, Json] = {}
  paths[self.endpoint.path] = Json::object(operation_by_method)
  let root : Map[String, Json] = {
    "openapi": Json::string(self.openapi_version),
    "paths": Json::object(paths),
  }
  if self.components is Some(components) {
    root["components"] = components
  }
  Json::object(root)
}

///|
pub fn format_endpoint_subset(
  subset : EndpointSubset,
  format : EndpointGetFormat,
) -> String {
  match format {
    EndpointGetJson => subset.to_json().stringify(indent=2)
    EndpointGetMarkdown => endpoint_subset_to_markdown(subset)
  }
}

///|
fn endpoint_subset_to_markdown(subset : EndpointSubset) -> String {
  let buf = StringBuilder::new()
  buf.write_string(
    "## \{subset.endpoint.http_method} \{subset.endpoint.path}\n\n",
  )
  buf.write_string("operationId: \{subset.endpoint.operation_id}\n")
  if subset.endpoint.tags.length() > 0 {
    let tags = subset.endpoint.tags.join(", ")
    buf.write_string("tags: \{tags}\n")
  }
  if subset.endpoint.summary is Some(summary) {
    buf.write_string("summary: \{summary}\n")
  }
  if subset.operation is Object(operation) {
    match operation.get("parameters") {
      Some(parameters) => write_json_section(buf, "Parameters", parameters)
      None => ()
    }
    match operation.get("requestBody") {
      Some(request_body) =>
        write_json_section(buf, "Request Body", request_body)
      None => ()
    }
    match operation.get("responses") {
      Some(responses) => write_json_section(buf, "Responses", responses)
      None => ()
    }
  }
  if subset.components is Some(components) {
    write_json_section(buf, "Components", components)
  }
  buf.to_string()
}

///|
fn write_json_section(
  buf : StringBuilder,
  title : String,
  value : Json,
) -> Unit {
  buf.write_string("\n### \{title}\n\n")
  buf.write_string("```json\n")
  buf.write_string(value.stringify(indent=2))
  buf.write_string("\n```\n")
}
