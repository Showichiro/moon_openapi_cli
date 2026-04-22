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
