///|
fn ref_location_from_input(input : String) -> RefDocumentLocation {
  match classify_input_source(input) {
    Stdin => NoRefDocument
    LocalFile(path) => LocalRefDocument(normalize_path(path))
    RemoteUrl(url) => RemoteRefDocument(url)
    UnsupportedUrl(_) => NoRefDocument
  }
}

///|
fn split_ref(ref_value : String) -> (String, String)? {
  match ref_value.split_once("#") {
    Some((document_ref, fragment)) =>
      Some((document_ref.to_string(), fragment.to_string()))
    None => None
  }
}

///|
fn decode_ref_fragment(fragment : String) -> Array[String]? {
  @json_pointer.decode_fragment(fragment)
}

///|
fn resolve_ref_document_location(
  current : RefDocumentLocation,
  document_ref : String,
) -> RefDocumentLocation? {
  if document_ref.is_empty() {
    match current {
      NoRefDocument => None
      _ => Some(current)
    }
  } else if document_ref.has_prefix("http://") ||
    document_ref.has_prefix("https://") {
    Some(RemoteRefDocument(document_ref))
  } else if document_ref.find("://") is Some(_) {
    None
  } else {
    match current {
      NoRefDocument => None
      LocalRefDocument(path) =>
        Some(LocalRefDocument(resolve_local_ref(path, document_ref)))
      RemoteRefDocument(url) =>
        Some(RemoteRefDocument(resolve_remote_ref(url, document_ref)))
    }
  }
}

///|
fn resolve_local_ref(base_file : String, document_ref : String) -> String {
  if document_ref.has_prefix("/") {
    normalize_path(document_ref)
  } else {
    let base_dir = local_dirname(base_file)
    if base_dir == "." {
      normalize_path(document_ref)
    } else {
      normalize_path(base_dir + "/" + document_ref)
    }
  }
}

///|
fn resolve_remote_ref(base_url : String, document_ref : String) -> String {
  let clean_base = strip_url_suffix(base_url)
  if document_ref.has_prefix("/") {
    remote_origin(clean_base) + normalize_path(document_ref)
  } else {
    normalize_url_path(remote_dirname(clean_base) + document_ref)
  }
}

///|
fn strip_url_suffix(url : String) -> String {
  match url.split_once("#") {
    Some((base, _)) => base.to_string()
    None =>
      match url.split_once("?") {
        Some((base, _)) => base.to_string()
        None => url
      }
  }
}

///|
fn remote_origin(url : String) -> String {
  match url.find("://") {
    None => ""
    Some(scheme_end) => {
      let host_start = scheme_end + 3
      let rest = url[host_start:]
      match rest.find("/") {
        None => url
        Some(path_start) => url[:host_start + path_start].to_string()
      }
    }
  }
}

///|
fn remote_dirname(url : String) -> String {
  let origin = remote_origin(url)
  let path = url[origin.length():].to_string()
  let dir = local_dirname(path)
  if dir == "." {
    origin + "/"
  } else if dir == "/" {
    origin + "/"
  } else {
    origin + dir + "/"
  }
}

///|
fn normalize_url_path(url : String) -> String {
  let origin = remote_origin(url)
  if origin.is_empty() {
    normalize_path(url)
  } else {
    let path = url[origin.length():].to_string()
    origin + normalize_path(path)
  }
}

///|
fn local_dirname(path : String) -> String {
  let parts : Array[String] = path
    .split("/")
    .map(part => part.to_string())
    .collect()
  if parts.length() <= 1 {
    "."
  } else {
    let dir_parts = parts[:parts.length() - 1]
    if dir_parts.length() == 1 && dir_parts[0].is_empty() {
      "/"
    } else if dir_parts.length() == 0 {
      "."
    } else {
      dir_parts.join("/")
    }
  }
}

///|
fn normalize_path(path : String) -> String {
  let absolute = path.has_prefix("/")
  let stack : Array[String] = []
  for view in path.split("/") {
    let part = view.to_string()
    if part.is_empty() || part == "." {
      ()
    } else if part == ".." {
      if stack.length() > 0 && stack[stack.length() - 1] != ".." {
        let _ = stack.pop()
      } else if !absolute {
        stack.push(part)
      }
    } else {
      stack.push(part)
    }
  }
  let normalized = stack.join("/")
  if absolute {
    "/" + normalized
  } else if normalized.is_empty() {
    "."
  } else {
    normalized
  }
}

///|
fn location_key(location : RefDocumentLocation) -> String {
  match location {
    NoRefDocument => "none:"
    LocalRefDocument(path) => "file:\{path}"
    RemoteRefDocument(url) => "url:\{url}"
  }
}

///|
fn import_key(location : RefDocumentLocation, tokens : Array[String]) -> String {
  location_key(location) + "#" + tokens.join("/")
}
