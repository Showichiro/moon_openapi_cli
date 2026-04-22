///|
test "format warnings as text by default shape" {
  let output = format_warnings(
    ["unsupported external $ref: external.json#/components/schemas/Photo"],
    WarningText,
  )
  inspect(
    output,
    content="warning: unsupported external $ref: external.json#/components/schemas/Photo\n",
  )
}

///|
test "format warnings as json lines with classified ref" {
  let output = format_warnings(
    ["unsupported external $ref: external.json#/components/schemas/Photo"],
    WarningJson,
  )
  assert_true(output.contains("\"level\":\"warning\""))
  assert_true(output.contains("\"code\":\"unsupported_external_ref\""))
  assert_true(
    output.contains("\"ref\":\"external.json#/components/schemas/Photo\""),
  )
  assert_true(output.has_suffix("\n"))
}

///|
test "format warnings supports internal ref and generic warning" {
  let internal = warning_to_json_line("unsupported internal $ref: #/x/y")
  assert_true(internal.contains("\"code\":\"unsupported_internal_ref\""))
  assert_true(internal.contains("\"ref\":\"#/x/y\""))
  let generic = warning_to_json_line("some warning")
  assert_true(generic.contains("\"code\":\"warning\""))
  assert_false(generic.contains("\"ref\""))
}

///|
test "format warnings classifies external ref resolver failures" {
  let load = warning_to_json_line(
    "external $ref load failed: photo.json#/components/schemas/Photo -- missing",
  )
  assert_true(load.contains("\"code\":\"external_ref_load_failed\""))
  assert_true(load.contains("\"ref\":\"photo.json#/components/schemas/Photo\""))
  let parse = warning_to_json_line(
    "external $ref parse failed: photo.json#/components/schemas/Photo -- bad json",
  )
  assert_true(parse.contains("\"code\":\"external_ref_parse_failed\""))
  let missing = warning_to_json_line(
    "external $ref pointer not found: photo.json#/components/schemas/Photo",
  )
  assert_true(missing.contains("\"code\":\"external_ref_pointer_not_found\""))
  let conflict = warning_to_json_line(
    "external $ref conflict: photo.json#/components/schemas/Photo -- target already exists",
  )
  assert_true(conflict.contains("\"code\":\"external_ref_conflict\""))
}

///|
test "format warnings can be suppressed" {
  assert_eq(format_warnings(["some warning"], WarningNone), "")
}
