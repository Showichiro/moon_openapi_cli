///|
async fn endpoint_ls(matches : @argparse.Matches) -> Unit {
  let trace = new_verbose_trace(matches)
  let content_result = read_command_input(trace, matches)
  match content_result {
    Err(message) => exit_with_input_error(trace, message)
    Ok((_, content)) => {
      let options = @lib.endpoint_list_options(
        option_value(matches, "tag"),
        option_value(matches, "method"),
      )
      let extract_start = trace_now_ms()
      let extracted = @lib.list_endpoints_from_source(content, options~)
      exit_with_extract_result(
        trace,
        matches,
        extract_start,
        extracted,
        resolve_list_format,
        (endpoints, format) => @lib.format_endpoint_list(endpoints, format),
      )
    }
  }
}

///|
async fn endpoint_get(matches : @argparse.Matches) -> Unit {
  let trace = new_verbose_trace(matches)
  let target_result = positional_target(matches)
  match target_result {
    Err(err) => {
      write_trace_total(trace)
      exit_with_error(err)
    }
    Ok(target) => {
      let content_result = read_command_input(trace, matches)
      match content_result {
        Err(message) => exit_with_input_error(trace, message)
        Ok((file, content)) => {
          let options = @lib.endpoint_get_options(
            matches.flags.get_or_default("no-resolve", false),
            inline_refs=matches.flags.get_or_default("inline-refs", false),
          )
          let extract_start = trace_now_ms()
          match
            resolve_endpoint_with_external_refs(content, file, target, options) {
            Err(err) => {
              write_trace_phase(trace, "extract", extract_start, trace_now_ms())
              write_trace_total(trace)
              exit_with_operation_error(err, target, content, file)
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
                  let output = match resolve_get_format(matches) {
                    Err(err) => Err(err)
                    Ok(format) =>
                      Ok(@lib.format_endpoint_subset(resolved.subset, format))
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
async fn endpoint_search(matches : @argparse.Matches) -> Unit {
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
              let options = @lib.endpoint_search_options(
                option_value(matches, "tag"),
                option_value(matches, "method"),
                limit,
              )
              let extract_start = trace_now_ms()
              let extracted = @lib.search_endpoints_from_source(
                content,
                query,
                options~,
              )
              exit_with_extract_result(
                trace,
                matches,
                extract_start,
                extracted,
                resolve_endpoint_search_format,
                (results, format) => {
                  @lib.format_endpoint_search_results(results, format)
                },
              )
            }
          }
        }
      }
    }
  }
}
