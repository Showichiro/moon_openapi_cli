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
