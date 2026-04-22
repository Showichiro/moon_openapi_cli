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
fn read_file(path : String) -> Result[String, String] {
  decode_io_result(read_file_ffi(@utf8.encode(path)))
}

///|
fn read_stdin() -> Result[String, String] {
  decode_io_result(read_stdin_ffi())
}

///|
fn decode_io_result(bytes : Bytes) -> Result[String, String] {
  if bytes.length() == 0 {
    Err("I/O operation returned an empty status payload")
  } else {
    let payload = @utf8.decode_lossy(bytes[1:])
    if bytes[0].to_int() == 0 {
      Ok(payload)
    } else {
      Err(payload)
    }
  }
}

///|
fn write_stdout(output : String) -> Unit {
  write_stdout_ffi(@utf8.encode(output))
}

///|
fn write_stderr(output : String) -> Unit {
  write_stderr_ffi(@utf8.encode(output))
}

///|
#borrow(path)
extern "c" fn read_file_ffi(path : Bytes) -> Bytes = "moonbit_apispec_read_file"

///|
extern "c" fn read_stdin_ffi() -> Bytes = "moonbit_apispec_read_stdin"

///|
#borrow(output)
extern "c" fn write_stdout_ffi(output : Bytes) -> Unit = "moonbit_apispec_write_stdout"

///|
#borrow(output)
extern "c" fn write_stderr_ffi(output : Bytes) -> Unit = "moonbit_apispec_write_stderr"
