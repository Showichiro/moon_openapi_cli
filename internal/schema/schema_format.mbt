///|
pub fn SchemaSummary::to_json(self : SchemaSummary) -> Json {
  let object : Map[String, Json] = { "name": Json::string(self.name) }
  if self.title is Some(title) {
    object["title"] = Json::string(title)
  }
  if self.schema_type is Some(schema_type) {
    object["type"] = Json::string(schema_type)
  }
  Json::object(object)
}

///|
pub fn format_schema_list(
  schemas : Array[SchemaSummary],
  format : SchemaListFormat,
) -> String {
  match format {
    SchemaListJsonLines =>
      schemas.map(schema => schema.to_json().stringify()).join("\n")
    SchemaListMarkdown => schemas.map(schema_to_markdown_line).join("\n")
    SchemaListQuiet => schemas.map(schema => schema.name).join("\n")
  }
}

///|
fn schema_to_markdown_line(schema : SchemaSummary) -> String {
  let with_type = match schema.schema_type {
    Some(schema_type) => "- \{schema.name} (\{schema_type})"
    None => "- \{schema.name}"
  }
  match schema.title {
    Some(title) => "\{with_type} - \{title}"
    None => with_type
  }
}

///|
pub fn SchemaSearchResult::to_json(self : SchemaSearchResult) -> Json {
  let object : Map[String, Json] = {
    "name": Json::string(self.name),
    "score": Json::number(self.score.to_double()),
    "matchedFields": Json::array(
      self.matched_fields.map(field => Json::string(field)),
    ),
  }
  if self.title is Some(title) {
    object["title"] = Json::string(title)
  }
  if self.schema_type is Some(schema_type) {
    object["type"] = Json::string(schema_type)
  }
  Json::object(object)
}

///|
pub fn format_schema_search_results(
  results : Array[SchemaSearchResult],
  format : SchemaSearchFormat,
) -> String {
  match format {
    SchemaSearchJsonLines =>
      results.map(result => result.to_json().stringify()).join("\n")
    SchemaSearchMarkdown =>
      results.map(schema_search_to_markdown_line).join("\n")
    SchemaSearchQuiet => results.map(result => result.name).join("\n")
  }
}

///|
fn schema_search_to_markdown_line(result : SchemaSearchResult) -> String {
  let with_type = match result.schema_type {
    Some(schema_type) =>
      "- \{result.name} (\{schema_type}, score: \{result.score})"
    None => "- \{result.name} (score: \{result.score})"
  }
  match result.title {
    Some(title) => "\{with_type} - \{title}"
    None => with_type
  }
}

///|
pub fn SchemaSubset::to_json(self : SchemaSubset) -> Json {
  let root : Map[String, Json] = {
    "openapi": Json::string(self.openapi_version),
  }
  if self.components is Some(components) {
    root["components"] = components
  }
  if self.usages is Some(usages) {
    root["usages"] = Json::array(usages.map(usage => usage.to_json()))
  }
  Json::object(root)
}

///|
pub fn format_schema_subset(
  subset : SchemaSubset,
  format : SchemaGetFormat,
) -> String {
  match format {
    SchemaGetJson => subset.to_json().stringify(indent=2)
    SchemaGetMarkdown => schema_subset_to_markdown(subset)
  }
}

///|
fn schema_subset_to_markdown(subset : SchemaSubset) -> String {
  let buf = StringBuilder::new()
  buf.write_string("## \{subset.name}\n")
  @markdown.write_json_section(buf, "Schema", subset.schema)
  if subset.components is Some(components) {
    @markdown.write_json_section(buf, "Components", components)
  }
  if subset.usages is Some(usages) {
    buf.write_string("\n### Usages\n\n")
    if usages.length() == 0 {
      buf.write_string("- none\n")
    } else {
      for usage in usages {
        buf.write_string(@endpoint.endpoint_to_markdown_line(usage) + "\n")
      }
    }
  }
  buf.to_string()
}
