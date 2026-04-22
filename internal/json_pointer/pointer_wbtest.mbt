///|
test "decode fragment and encode ref escapes pointer tokens" {
  let tokens = decode_fragment("/components/schemas/Slash~1Pet/Tilde~0Name").unwrap()
  assert_eq(tokens, ["components", "schemas", "Slash/Pet", "Tilde~Name"])
  assert_eq(encode_ref(tokens), "#/components/schemas/Slash~1Pet/Tilde~0Name")
}

///|
test "get follows object properties and array indexes" {
  let document : Json = {
    "components": {
      "schemas": {
        "Pet": { "allOf": [{ "type": "object" }, { "type": "string" }] },
      },
    },
  }
  let tokens : Array[String] = [
    "components", "schemas", "Pet", "allOf", "1", "type",
  ]
  assert_eq(get(document, tokens), Some(Json::string("string")))
  assert_eq(get(document, ["components", "schemas", "Pet", "allOf", "2"]), None)
  assert_eq(
    get(document, ["components", "schemas", "Pet", "allOf", "-1"]),
    None,
  )
}
