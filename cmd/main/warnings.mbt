///|
priv enum WarningOutputFormat {
  WarningText
  WarningJson
  WarningNone
}

///|
const UNSUPPORTED_EXTERNAL_REF_PREFIX : String = "unsupported external $ref: "

///|
const UNSUPPORTED_INTERNAL_REF_PREFIX : String = "unsupported internal $ref: "

///|
const EXTERNAL_REF_LOAD_FAILED_PREFIX : String = "external $ref load failed: "

///|
const EXTERNAL_REF_PARSE_FAILED_PREFIX : String = "external $ref parse failed: "

///|
const EXTERNAL_REF_POINTER_NOT_FOUND_PREFIX : String = "external $ref pointer not found: "

///|
const EXTERNAL_REF_CONFLICT_PREFIX : String = "external $ref conflict: "

///|
fn write_warnings(
  warnings : Array[String],
  format : WarningOutputFormat,
) -> Unit {
  let output = format_warnings(warnings, format)
  if !output.is_empty() {
    write_stderr(output)
  }
}

///|
fn format_warnings(
  warnings : Array[String],
  format : WarningOutputFormat,
) -> String {
  match format {
    WarningNone => ""
    WarningText => format_text_warnings(warnings)
    WarningJson => format_json_warnings(warnings)
  }
}

///|
fn format_text_warnings(warnings : Array[String]) -> String {
  let lines : Array[String] = []
  for warning in warnings {
    lines.push("warning: \{warning}")
  }
  join_warning_lines(lines)
}

///|
fn format_json_warnings(warnings : Array[String]) -> String {
  let lines : Array[String] = []
  for warning in warnings {
    lines.push(warning_to_json_line(warning))
  }
  join_warning_lines(lines)
}

///|
fn join_warning_lines(lines : Array[String]) -> String {
  if lines.length() == 0 {
    ""
  } else {
    lines.join("\n") + "\n"
  }
}

///|
fn warning_to_json_line(message : String) -> String {
  let object : Map[String, Json] = {
    "level": Json::string("warning"),
    "code": Json::string(warning_code(message)),
    "message": Json::string(message),
  }
  match warning_ref(message) {
    Some(ref_value) => object["ref"] = Json::string(ref_value)
    None => ()
  }
  Json::object(object).stringify()
}

///|
fn warning_code(message : String) -> String {
  if message.has_prefix(UNSUPPORTED_EXTERNAL_REF_PREFIX) {
    "unsupported_external_ref"
  } else if message.has_prefix(UNSUPPORTED_INTERNAL_REF_PREFIX) {
    "unsupported_internal_ref"
  } else if message.has_prefix(EXTERNAL_REF_LOAD_FAILED_PREFIX) {
    "external_ref_load_failed"
  } else if message.has_prefix(EXTERNAL_REF_PARSE_FAILED_PREFIX) {
    "external_ref_parse_failed"
  } else if message.has_prefix(EXTERNAL_REF_POINTER_NOT_FOUND_PREFIX) {
    "external_ref_pointer_not_found"
  } else if message.has_prefix(EXTERNAL_REF_CONFLICT_PREFIX) {
    "external_ref_conflict"
  } else {
    "warning"
  }
}

///|
fn warning_ref(message : String) -> String? {
  if message.has_prefix(UNSUPPORTED_EXTERNAL_REF_PREFIX) {
    Some(message[UNSUPPORTED_EXTERNAL_REF_PREFIX.length():].to_string())
  } else if message.has_prefix(UNSUPPORTED_INTERNAL_REF_PREFIX) {
    Some(message[UNSUPPORTED_INTERNAL_REF_PREFIX.length():].to_string())
  } else if message.has_prefix(EXTERNAL_REF_LOAD_FAILED_PREFIX) {
    warning_ref_with_detail(message, EXTERNAL_REF_LOAD_FAILED_PREFIX)
  } else if message.has_prefix(EXTERNAL_REF_PARSE_FAILED_PREFIX) {
    warning_ref_with_detail(message, EXTERNAL_REF_PARSE_FAILED_PREFIX)
  } else if message.has_prefix(EXTERNAL_REF_POINTER_NOT_FOUND_PREFIX) {
    Some(message[EXTERNAL_REF_POINTER_NOT_FOUND_PREFIX.length():].to_string())
  } else if message.has_prefix(EXTERNAL_REF_CONFLICT_PREFIX) {
    warning_ref_with_detail(message, EXTERNAL_REF_CONFLICT_PREFIX)
  } else {
    None
  }
}

///|
fn warning_ref_with_detail(message : String, prefix : String) -> String? {
  let value = message[prefix.length():].to_string()
  match value.find(" -- ") {
    Some(detail_start) => Some(value[:detail_start].to_string())
    None => Some(value)
  }
}
