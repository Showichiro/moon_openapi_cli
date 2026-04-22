///|
enum CliOutputFormat {
  CliJson
  CliMarkdown
}

///|
fn resolve_output_format(
  matches : @argparse.Matches,
) -> Result[CliOutputFormat, @lib.ApispecError] {
  match option_value(matches, "format").unwrap_or("json") {
    "json" => Ok(CliJson)
    "md" => Ok(CliMarkdown)
    value => Err(@lib.ApispecError::UsageError("unsupported format: \{value}"))
  }
}

///|
fn quiet_requested(matches : @argparse.Matches) -> Bool {
  matches.flags.get_or_default("quiet", false)
}

///|
fn resolve_endpoint_search_format(
  matches : @argparse.Matches,
) -> Result[@lib.EndpointSearchFormat, @lib.ApispecError] {
  if quiet_requested(matches) {
    Ok(@lib.EndpointSearchFormat::EndpointSearchQuiet)
  } else {
    match resolve_output_format(matches) {
      Ok(CliJson) => Ok(@lib.EndpointSearchFormat::EndpointSearchJsonLines)
      Ok(CliMarkdown) => Ok(@lib.EndpointSearchFormat::EndpointSearchMarkdown)
      Err(err) => Err(err)
    }
  }
}

///|
fn resolve_schema_search_format(
  matches : @argparse.Matches,
) -> Result[@lib.SchemaSearchFormat, @lib.ApispecError] {
  if quiet_requested(matches) {
    Ok(@lib.SchemaSearchFormat::SchemaSearchQuiet)
  } else {
    match resolve_output_format(matches) {
      Ok(CliJson) => Ok(@lib.SchemaSearchFormat::SchemaSearchJsonLines)
      Ok(CliMarkdown) => Ok(@lib.SchemaSearchFormat::SchemaSearchMarkdown)
      Err(err) => Err(err)
    }
  }
}

///|
fn resolve_list_format(
  matches : @argparse.Matches,
) -> Result[@lib.EndpointListFormat, @lib.ApispecError] {
  if quiet_requested(matches) {
    Ok(@lib.EndpointListFormat::Quiet)
  } else {
    match resolve_output_format(matches) {
      Ok(CliJson) => Ok(@lib.EndpointListFormat::JsonLines)
      Ok(CliMarkdown) => Ok(@lib.EndpointListFormat::Markdown)
      Err(err) => Err(err)
    }
  }
}

///|
fn resolve_get_format(
  matches : @argparse.Matches,
) -> Result[@lib.EndpointGetFormat, @lib.ApispecError] {
  match resolve_output_format(matches) {
    Ok(CliJson) => Ok(@lib.EndpointGetFormat::EndpointGetJson)
    Ok(CliMarkdown) => Ok(@lib.EndpointGetFormat::EndpointGetMarkdown)
    Err(err) => Err(err)
  }
}

///|
fn resolve_schema_list_format(
  matches : @argparse.Matches,
) -> Result[@lib.SchemaListFormat, @lib.ApispecError] {
  if quiet_requested(matches) {
    Ok(@lib.SchemaListFormat::SchemaListQuiet)
  } else {
    match resolve_output_format(matches) {
      Ok(CliJson) => Ok(@lib.SchemaListFormat::SchemaListJsonLines)
      Ok(CliMarkdown) => Ok(@lib.SchemaListFormat::SchemaListMarkdown)
      Err(err) => Err(err)
    }
  }
}

///|
fn resolve_schema_get_format(
  matches : @argparse.Matches,
) -> Result[@lib.SchemaGetFormat, @lib.ApispecError] {
  match resolve_output_format(matches) {
    Ok(CliJson) => Ok(@lib.SchemaGetFormat::SchemaGetJson)
    Ok(CliMarkdown) => Ok(@lib.SchemaGetFormat::SchemaGetMarkdown)
    Err(err) => Err(err)
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
