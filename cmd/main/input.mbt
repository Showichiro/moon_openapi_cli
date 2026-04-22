///|
enum InputSource {
  Stdin
  LocalFile(String)
  RemoteUrl(String)
  UnsupportedUrl(String)
} derive(Eq, Debug)

///|
fn classify_input_source(source : String) -> InputSource {
  if source == "-" {
    Stdin
  } else if source.has_prefix("http://") || source.has_prefix("https://") {
    RemoteUrl(source)
  } else {
    match source.find("://") {
      Some(protocol_len) => UnsupportedUrl(source[:protocol_len].to_string())
      None => LocalFile(source)
    }
  }
}

///|
async fn read_input_with_trace(
  trace : VerboseTrace,
  source : String,
) -> Result[String, String] {
  let load_start = trace_now_ms()
  let result = read_input(source)
  let load_end = trace_now_ms()
  write_trace_phase(trace, "load", load_start, load_end)
  result
}

///|
async fn read_input(source : String) -> Result[String, String] {
  match classify_input_source(source) {
    Stdin => read_stdin()
    LocalFile(path) => read_file(path)
    RemoteUrl(url) => fetch_url(url)
    UnsupportedUrl(scheme) => Err("unsupported input URL scheme: \{scheme}")
  }
}

///|
async fn fetch_url(url : String) -> Result[String, String] {
  match @async.with_timeout_opt(10000, () => fetch_url_without_timeout(url)) {
    Some(result) => result
    None => Err("timed out fetching '\{url}' after 10000ms")
  }
}

///|
async fn fetch_url_without_timeout(url : String) -> Result[String, String] {
  let result = try? @http.get(url)
  match result {
    Err(err) => Err("failed to fetch '\{url}': \{err}")
    Ok((response, body)) =>
      if response.code >= 200 && response.code < 300 {
        let text_result = try? body.text()
        match text_result {
          Ok(text) => Ok(text)
          Err(err) =>
            Err("failed to decode response body from '\{url}': \{err}")
        }
      } else {
        Err(
          "failed to fetch '\{url}': HTTP \{response.code} \{response.reason}",
        )
      }
  }
}

///|
async fn read_file(path : String) -> Result[String, String] {
  let result : Result[&@io.Data, _] = try? @fs.read_file(path)
  match result {
    Ok(data) => Ok(@utf8.decode_lossy(data.binary()))
    Err(err) => Err("failed to read '\{path}': \{err}")
  }
}

///|
async fn read_stdin() -> Result[String, String] {
  let result : Result[&@io.Data, _] = try? @stdio.stdin.read_all()
  match result {
    Ok(data) => Ok(@utf8.decode_lossy(data.binary()))
    Err(err) => Err("failed to read stdin: \{err}")
  }
}

///|
async fn write_stdout(output : String) -> Unit {
  @stdio.stdout.write(output)
}

///|
async fn write_stderr(output : String) -> Unit {
  @stdio.stderr.write(output)
}
