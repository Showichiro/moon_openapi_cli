///|
test "classify input source" {
  assert_true(classify_input_source("-") is Stdin)
  assert_true(
    classify_input_source("openapi.json") is LocalFile("openapi.json"),
  )
  assert_true(
    classify_input_source("http://example.com/openapi.json")
    is RemoteUrl("http://example.com/openapi.json"),
  )
  assert_true(
    classify_input_source("https://example.com/openapi.json")
    is RemoteUrl("https://example.com/openapi.json"),
  )
  assert_true(
    classify_input_source("ftp://example.com/openapi.json")
    is UnsupportedUrl("ftp"),
  )
  assert_true(
    classify_input_source("HTTPS://example.com/openapi.json")
    is UnsupportedUrl("HTTPS"),
  )
}
