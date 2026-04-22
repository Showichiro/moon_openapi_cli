///|
fn positional_target(
  matches : @argparse.Matches,
) -> Result[String, @lib.ApispecError] {
  match matches.values.get("target") {
    Some(values) =>
      match values.length() {
        1 => Ok(values[0])
        2 => Ok(values[0] + " " + values[1])
        _ => Err(@lib.UsageError("expected one endpoint target"))
      }
    None => Err(@lib.UsageError("expected one endpoint target"))
  }
}

///|
fn single_positional(
  matches : @argparse.Matches,
  name : String,
) -> Result[String, @lib.ApispecError] {
  match matches.values.get(name) {
    Some(values) =>
      if values.length() == 1 {
        Ok(values[0])
      } else {
        Err(@lib.UsageError("expected one \{name} value"))
      }
    None => Err(@lib.UsageError("expected one \{name} value"))
  }
}

///|
fn joined_positional(
  matches : @argparse.Matches,
  name : String,
) -> Result[String, @lib.ApispecError] {
  match matches.values.get(name) {
    Some(values) =>
      if values.length() > 0 {
        Ok(values.join(" "))
      } else {
        Err(@lib.UsageError("expected one or more \{name} values"))
      }
    None => Err(@lib.UsageError("expected one or more \{name} values"))
  }
}

///|
fn option_value(matches : @argparse.Matches, name : String) -> String? {
  match matches.values.get(name) {
    Some(values) =>
      if values.length() > 0 {
        Some(values[values.length() - 1])
      } else {
        None
      }
    None => None
  }
}

///|
fn resolve_limit(matches : @argparse.Matches) -> Result[Int, @lib.ApispecError] {
  let value = option_value(matches, "limit").unwrap_or("10")
  let parsed : Result[Int, _] = try? @string.parse_int(value)
  match parsed {
    Err(_) => Err(@lib.UsageError("unsupported limit: \{value}"))
    Ok(limit) =>
      if limit <= 0 {
        Err(@lib.UsageError("limit must be greater than 0"))
      } else {
        Ok(limit)
      }
  }
}

///|
fn resolve_endpoint_search_format(
  matches : @argparse.Matches,
) -> Result[@lib.EndpointSearchFormat, @lib.ApispecError] {
  if matches.flags.get_or_default("quiet", false) {
    Ok(@lib.EndpointSearchQuiet)
  } else {
    match option_value(matches, "format").unwrap_or("json") {
      "json" => Ok(@lib.EndpointSearchJsonLines)
      "md" => Ok(@lib.EndpointSearchMarkdown)
      value => Err(@lib.UsageError("unsupported format: \{value}"))
    }
  }
}

///|
fn resolve_schema_search_format(
  matches : @argparse.Matches,
) -> Result[@lib.SchemaSearchFormat, @lib.ApispecError] {
  if matches.flags.get_or_default("quiet", false) {
    Ok(@lib.SchemaSearchQuiet)
  } else {
    match option_value(matches, "format").unwrap_or("json") {
      "json" => Ok(@lib.SchemaSearchJsonLines)
      "md" => Ok(@lib.SchemaSearchMarkdown)
      value => Err(@lib.UsageError("unsupported format: \{value}"))
    }
  }
}

///|
fn resolve_list_format(
  matches : @argparse.Matches,
) -> Result[@lib.EndpointListFormat, @lib.ApispecError] {
  if matches.flags.get_or_default("quiet", false) {
    Ok(@lib.Quiet)
  } else {
    match option_value(matches, "format").unwrap_or("json") {
      "json" => Ok(@lib.JsonLines)
      "md" => Ok(@lib.Markdown)
      value => Err(@lib.UsageError("unsupported format: \{value}"))
    }
  }
}

///|
fn resolve_get_format(
  matches : @argparse.Matches,
) -> Result[@lib.EndpointGetFormat, @lib.ApispecError] {
  match option_value(matches, "format").unwrap_or("json") {
    "json" => Ok(@lib.EndpointGetJson)
    "md" => Ok(@lib.EndpointGetMarkdown)
    value => Err(@lib.UsageError("unsupported format: \{value}"))
  }
}

///|
fn resolve_schema_list_format(
  matches : @argparse.Matches,
) -> Result[@lib.SchemaListFormat, @lib.ApispecError] {
  if matches.flags.get_or_default("quiet", false) {
    Ok(@lib.SchemaListQuiet)
  } else {
    match option_value(matches, "format").unwrap_or("json") {
      "json" => Ok(@lib.SchemaListJsonLines)
      "md" => Ok(@lib.SchemaListMarkdown)
      value => Err(@lib.UsageError("unsupported format: \{value}"))
    }
  }
}

///|
fn resolve_schema_get_format(
  matches : @argparse.Matches,
) -> Result[@lib.SchemaGetFormat, @lib.ApispecError] {
  match option_value(matches, "format").unwrap_or("json") {
    "json" => Ok(@lib.SchemaGetJson)
    "md" => Ok(@lib.SchemaGetMarkdown)
    value => Err(@lib.UsageError("unsupported format: \{value}"))
  }
}

///|
fn resolve_warning_format(
  matches : @argparse.Matches,
) -> Result[WarningOutputFormat, @lib.ApispecError] {
  match option_value(matches, "warnings").unwrap_or("text") {
    "text" => Ok(WarningText)
    "json" => Ok(WarningJson)
    "none" => Ok(WarningNone)
    value => Err(@lib.UsageError("unsupported warnings: \{value}"))
  }
}
