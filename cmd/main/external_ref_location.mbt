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
