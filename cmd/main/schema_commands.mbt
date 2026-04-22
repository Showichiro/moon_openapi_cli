///|
async fn schema_ls(matches : @argparse.Matches) -> Unit {
  let trace = new_verbose_trace(matches)
  let content_result = read_command_input(trace, matches)
  match content_result {
    Err(message) => exit_with_input_error(trace, message)
    Ok((_, content)) => {
      let extract_start = trace_now_ms()
      match @lib.list_schemas_from_source(content) {
        Err(err) => {
          write_trace_phase(trace, "extract", extract_start, trace_now_ms())
          write_trace_total(trace)
          exit_with_error(err)
        }
        Ok(schemas) => {
          write_trace_phase(trace, "extract", extract_start, trace_now_ms())
          let format_start = trace_now_ms()
          let output = match resolve_schema_list_format(matches) {
            Err(err) => Err(err)
            Ok(format) => Ok(@lib.format_schema_list(schemas, format))
          }
          exit_with_formatted_output(trace, matches, format_start, output)
        }
      }
    }
  }
}

///|
async fn schema_get(matches : @argparse.Matches) -> Unit {
  let trace = new_verbose_trace(matches)
  let name_result = single_positional(matches, "name")
  match name_result {
    Err(err) => {
      write_trace_total(trace)
      exit_with_error(err)
    }
    Ok(name) => {
      let content_result = read_command_input(trace, matches)
      match content_result {
        Err(message) => exit_with_input_error(trace, message)
        Ok((file, content)) => {
          let options = @lib.schema_get_options(
            matches.flags.get_or_default("with-usages", false),
          )
          let extract_start = trace_now_ms()
          match
            resolve_schema_with_external_refs(content, file, name, options) {
            Err(err) => {
              write_trace_phase(trace, "extract", extract_start, trace_now_ms())
              write_trace_total(trace)
              exit_with_schema_error(err, name, content, file)
            }
            Ok(resolved) => {
              write_trace_phase(trace, "extract", extract_start, trace_now_ms())
              match resolve_warning_format(matches) {
                Err(err) => {
                  write_trace_total(trace)
                  exit_with_warning_format_error(err, matches)
                }
                Ok(warning_format) => {
                  write_warnings(resolved.warnings, warning_format)
                  let format_start = trace_now_ms()
                  let output = match resolve_schema_get_format(matches) {
                    Err(err) => Err(err)
                    Ok(format) =>
                      Ok(@lib.format_schema_subset(resolved.subset, format))
                  }
                  exit_with_formatted_output(
                    trace, matches, format_start, output,
                  )
                }
              }
            }
          }
        }
      }
    }
  }
}

///|
async fn schema_search(matches : @argparse.Matches) -> Unit {
  let trace = new_verbose_trace(matches)
  let query_result = joined_positional(matches, "query")
  match query_result {
    Err(err) => {
      write_trace_total(trace)
      exit_with_error(err)
    }
    Ok(query) => {
      let limit_result = resolve_limit(matches)
      match limit_result {
        Err(err) => {
          write_trace_total(trace)
          exit_with_limit_error(err, matches)
        }
        Ok(limit) => {
          let content_result = read_command_input(trace, matches)
          match content_result {
            Err(message) => exit_with_input_error(trace, message)
            Ok((_, content)) => {
              let options = @lib.schema_search_options(limit)
              let extract_start = trace_now_ms()
              match @lib.search_schemas_from_source(content, query, options~) {
                Err(err) => {
                  write_trace_phase(
                    trace,
                    "extract",
                    extract_start,
                    trace_now_ms(),
                  )
                  write_trace_total(trace)
                  exit_with_error(err)
                }
                Ok(results) => {
                  write_trace_phase(
                    trace,
                    "extract",
                    extract_start,
                    trace_now_ms(),
                  )
                  let format_start = trace_now_ms()
                  let output = match resolve_schema_search_format(matches) {
                    Err(err) => Err(err)
                    Ok(format) =>
                      Ok(@lib.format_schema_search_results(results, format))
                  }
                  exit_with_formatted_output(
                    trace, matches, format_start, output,
                  )
                }
              }
            }
          }
        }
      }
    }
  }
}
