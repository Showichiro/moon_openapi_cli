///|
test "format trace event as debug json line payload" {
  let output = format_trace_event("load", 7UL)
  assert_true(output.contains("\"level\":\"debug\""))
  assert_true(output.contains("\"phase\":\"load\""))
  assert_true(output.contains("\"durationMs\":7"))
}

///|
test "elapsed ms clamps backwards clocks to zero" {
  assert_eq(elapsed_ms(10UL, 15UL), 5UL)
  assert_eq(elapsed_ms(15UL, 10UL), 0UL)
}

///|
test "verbose flag is parsed on get commands" {
  let argv = ["schema", "get", "Pet", "--verbose"]
  let parsed : Result[@argparse.Matches, _] = try? command().parse(argv~)
  guard parsed is Ok(root_matches)
  guard root_matches.subcommand is Some(("schema", schema_matches))
  guard schema_matches.subcommand is Some(("get", get_matches))
  assert_true(get_matches.flags.get_or_default("verbose", false))
}

///|
test "verbose trace is disabled by default" {
  let argv = ["schema", "get", "Pet"]
  let parsed : Result[@argparse.Matches, _] = try? command().parse(argv~)
  guard parsed is Ok(root_matches)
  guard root_matches.subcommand is Some(("schema", schema_matches))
  guard schema_matches.subcommand is Some(("get", get_matches))
  let trace = new_verbose_trace(get_matches)
  assert_false(trace.enabled)
}
