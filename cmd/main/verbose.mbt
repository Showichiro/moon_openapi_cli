///|
priv struct VerboseTrace {
  enabled : Bool
  total_start : UInt64
}

///|
fn new_verbose_trace(matches : @argparse.Matches) -> VerboseTrace {
  {
    enabled: matches.flags.get_or_default("verbose", false),
    total_start: trace_now_ms(),
  }
}

///|
fn trace_now_ms() -> UInt64 {
  @env.now()
}

///|
async fn write_trace_phase(
  trace : VerboseTrace,
  phase : String,
  started_at : UInt64,
  ended_at : UInt64,
) -> Unit {
  if trace.enabled {
    write_stderr(
      format_trace_event(phase, elapsed_ms(started_at, ended_at)) + "\n",
    )
  }
}

///|
async fn write_trace_total(trace : VerboseTrace) -> Unit {
  write_trace_phase(trace, "total", trace.total_start, trace_now_ms())
}

///|
fn format_trace_event(phase : String, duration_ms : UInt64) -> String {
  Json::object({
    "level": Json::string("debug"),
    "phase": Json::string(phase),
    "durationMs": Json::number(duration_ms.to_double()),
  }).stringify()
}

///|
fn elapsed_ms(started_at : UInt64, ended_at : UInt64) -> UInt64 {
  if ended_at >= started_at {
    ended_at - started_at
  } else {
    0UL
  }
}
