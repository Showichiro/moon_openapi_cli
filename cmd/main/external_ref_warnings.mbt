///|
fn warn_external_once(
  ctx : ExternalRefContext,
  ref_value : String,
  message : String,
) -> Unit {
  let key = ref_value + "\n" + message
  if !ctx.warned.contains(key) {
    ctx.warned[key] = true
    ctx.warnings.push(message)
  }
}

///|
fn merge_cli_warnings(
  left : Array[String],
  right : Array[String],
) -> Array[String] {
  let merged : Array[String] = []
  append_cli_warnings(merged, left)
  append_cli_warnings(merged, right)
  merged
}

///|
fn append_cli_warnings(
  target : Array[String],
  warnings : Array[String],
) -> Unit {
  for warning in warnings {
    if !target.contains(warning) {
      target.push(warning)
    }
  }
}

///|
fn mark_blocked_refs(
  blocked : Map[String, Bool],
  warnings : Array[String],
) -> Unit {
  for warning in warnings {
    match warning_ref(warning) {
      Some(ref_value) => blocked[ref_value] = true
      None => ()
    }
  }
}
