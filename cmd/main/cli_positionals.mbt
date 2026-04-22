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
