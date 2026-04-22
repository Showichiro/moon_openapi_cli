///|
async fn exit_with_formatted_output(
  trace : VerboseTrace,
  matches : @argparse.Matches,
  format_start : UInt64,
  output : Result[String, @lib.ApispecError],
) -> Unit {
  match output {
    Err(err) => {
      write_trace_phase(trace, "format", format_start, trace_now_ms())
      write_trace_total(trace)
      exit_with_format_error(err, matches)
    }
    Ok(output) => {
      write_trace_phase(trace, "format", format_start, trace_now_ms())
      write_trace_total(trace)
      exit_success_output(output)
    }
  }
}
