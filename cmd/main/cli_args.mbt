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
