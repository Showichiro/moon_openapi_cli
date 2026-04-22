///|
fn suggestion_openapi() -> String {
  (
    #|{
    #|  "openapi": "3.0.3",
    #|  "paths": {
    #|    "/pets": {
    #|      "post": {
    #|        "operationId": "addPet",
    #|        "responses": {
    #|          "201": {
    #|            "description": "created"
    #|          }
    #|        }
    #|      }
    #|    },
    #|    "/pets/{id}": {
    #|      "get": {
    #|        "operationId": "getPet",
    #|        "responses": {
    #|          "200": {
    #|            "description": "ok"
    #|          }
    #|        }
    #|      }
    #|    }
    #|  },
    #|  "components": {
    #|    "schemas": {
    #|      "Pet": {
    #|        "type": "object"
    #|      },
    #|      "Category": {
    #|        "type": "object"
    #|      }
    #|    }
    #|  }
    #|}
  )
}

///|
test "closest candidate returns unique edit-distance match" {
  assert_eq(
    closest_candidate("addPett", ["listPets", "addPet"]),
    Some("addPet"),
  )
  assert_eq(closest_candidate("Pett", ["Category", "Pet"]), Some("Pet"))
}

///|
test "closest candidate rejects distant or tied matches" {
  assert_true(closest_candidate("abc", ["listPets"]) is None)
  assert_true(closest_candidate("abc", ["abd", "acc"]) is None)
}

///|
test "operation not found suggestion includes closest operation id" {
  let suggestion = endpoint_not_found_suggestion(
    "addPett",
    suggestion_openapi(),
    "openapi.json",
  )
  assert_true(suggestion.contains("did you mean 'addPet'?"))
  assert_true(
    suggestion.contains("apispec endpoint get addPet -f openapi.json"),
  )
  assert_true(suggestion.contains("apispec endpoint ls -f openapi.json"))
}

///|
test "schema not found suggestion includes closest schema name" {
  let suggestion = schema_not_found_suggestion(
    "Pett",
    suggestion_openapi(),
    "openapi.json",
  )
  assert_true(suggestion.contains("did you mean 'Pet'?"))
  assert_true(suggestion.contains("apispec schema get Pet -f openapi.json"))
  assert_true(suggestion.contains("apispec schema ls -f openapi.json"))
}

///|
test "not found suggestion falls back when candidates cannot be listed" {
  let suggestion = endpoint_not_found_suggestion("addPett", "[]", "broken.json")
  assert_false(suggestion.contains("did you mean"))
  assert_eq(
    suggestion, "run `apispec endpoint ls -f broken.json` to inspect available operations",
  )
}
