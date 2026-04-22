///|
pub fn openapi_version(root : Map[String, Json]) -> String {
  match root.get("openapi") {
    Some(String(version)) => version
    _ => "3.0.0"
  }
}
