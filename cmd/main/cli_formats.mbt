///|
fn resolve_endpoint_search_format(
  matches : @argparse.Matches,
) -> Result[@lib.EndpointSearchFormat, @lib.ApispecError] {
  if matches.flags.get_or_default("quiet", false) {
    Ok(@lib.EndpointSearchFormat::EndpointSearchQuiet)
  } else {
    match option_value(matches, "format").unwrap_or("json") {
      "json" => Ok(@lib.EndpointSearchFormat::EndpointSearchJsonLines)
      "md" => Ok(@lib.EndpointSearchFormat::EndpointSearchMarkdown)
      value =>
        Err(@lib.ApispecError::UsageError("unsupported format: \{value}"))
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
      value =>
        Err(@lib.ApispecError::UsageError("unsupported format: \{value}"))
    }
  }
}

///|
fn resolve_list_format(
  matches : @argparse.Matches,
) -> Result[@lib.EndpointListFormat, @lib.ApispecError] {
  if matches.flags.get_or_default("quiet", false) {
    Ok(@lib.EndpointListFormat::Quiet)
  } else {
    match option_value(matches, "format").unwrap_or("json") {
      "json" => Ok(@lib.EndpointListFormat::JsonLines)
      "md" => Ok(@lib.EndpointListFormat::Markdown)
      value =>
        Err(@lib.ApispecError::UsageError("unsupported format: \{value}"))
    }
  }
}

///|
fn resolve_get_format(
  matches : @argparse.Matches,
) -> Result[@lib.EndpointGetFormat, @lib.ApispecError] {
  match option_value(matches, "format").unwrap_or("json") {
    "json" => Ok(@lib.EndpointGetFormat::EndpointGetJson)
    "md" => Ok(@lib.EndpointGetFormat::EndpointGetMarkdown)
    value => Err(@lib.ApispecError::UsageError("unsupported format: \{value}"))
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
      value =>
        Err(@lib.ApispecError::UsageError("unsupported format: \{value}"))
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
    value => Err(@lib.ApispecError::UsageError("unsupported format: \{value}"))
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
    value =>
      Err(@lib.ApispecError::UsageError("unsupported warnings: \{value}"))
  }
}
