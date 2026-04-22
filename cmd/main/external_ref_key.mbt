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
