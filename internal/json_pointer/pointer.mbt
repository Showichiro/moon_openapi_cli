///|
pub fn decode_ref(ref_value : String) -> Array[String] {
  ref_value[2:].split("/").map(decode_token).collect()
}

///|
pub fn decode_fragment(fragment : String) -> Array[String]? {
  if !fragment.has_prefix("/") {
    None
  } else {
    Some(fragment[1:].split("/").map(decode_token).collect())
  }
}

///|
fn decode_token(token : StringView) -> String {
  token
  .replace_all(old="~1", new="/")
  .replace_all(old="~0", new="~")
  .to_string()
}

///|
pub fn encode_ref(tokens : Array[String]) -> String {
  "#/" + tokens.map(encode_token).join("/")
}

///|
fn encode_token(token : String) -> String {
  token.replace_all(old="~", new="~0").replace_all(old="/", new="~1")
}

///|
pub fn get(document : Json, tokens : Array[String]) -> Json? {
  let mut current = document
  for token in tokens {
    match current {
      Object(object) =>
        match object.get(token) {
          Some(next) => current = next
          None => return None
        }
      Array(items) =>
        match parse_array_index(token, items.length()) {
          Some(index) => current = items[index]
          None => return None
        }
      _ => return None
    }
  }
  Some(current)
}

///|
fn parse_array_index(token : String, length : Int) -> Int? {
  let parsed : Result[Int, _] = try? @string.parse_int(token)
  match parsed {
    Ok(index) => if index >= 0 && index < length { Some(index) } else { None }
    Err(_) => None
  }
}
