///|
async fn[Extracted, Format] exit_with_extract_result(
  trace : VerboseTrace,
  matches : @argparse.Matches,
  extract_start : UInt64,
  extracted : Result[Extracted, @lib.ApispecError],
  resolve_format : (@argparse.Matches) -> Result[Format, @lib.ApispecError],
  format_output : (Extracted, Format) -> String,
) -> Unit {
  match extracted {
    Err(err) => {
      write_trace_phase(trace, "extract", extract_start, trace_now_ms())
      write_trace_total(trace)
      exit_with_error(err)
    }
    Ok(value) => {
      write_trace_phase(trace, "extract", extract_start, trace_now_ms())
      let format_start = trace_now_ms()
      let output = match resolve_format(matches) {
        Err(err) => Err(err)
        Ok(format) => Ok(format_output(value, format))
      }
      exit_with_formatted_output(trace, matches, format_start, output)
    }
  }
}
