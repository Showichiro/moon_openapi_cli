///|
const GET : String = "GET"

///|
const POST : String = "POST"

///|
const PUT : String = "PUT"

///|
const DELETE : String = "DELETE"

///|
const PATCH : String = "PATCH"

///|
const OPTIONS : String = "OPTIONS"

///|
const HEAD : String = "HEAD"

///|
const TRACE : String = "TRACE"

///|
pub fn is_http_method(http_method : String) -> Bool {
  http_method == GET ||
  http_method == POST ||
  http_method == PUT ||
  http_method == DELETE ||
  http_method == PATCH ||
  http_method == OPTIONS ||
  http_method == HEAD ||
  http_method == TRACE
}

///|
pub fn rank(http_method : String) -> Int {
  match http_method {
    GET => 0
    POST => 1
    PUT => 2
    PATCH => 3
    DELETE => 4
    OPTIONS => 5
    HEAD => 6
    TRACE => 7
    _ => 99
  }
}
