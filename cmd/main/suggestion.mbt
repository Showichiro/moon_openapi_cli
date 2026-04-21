///|
fn endpoint_not_found_suggestion(
  target : String,
  content : String,
  file : String,
) -> String {
  match closest_operation_id(target, content) {
    Some(candidate) =>
      "did you mean '\{candidate}'? run `apispec endpoint get \{candidate} -f \{file}` or `apispec endpoint ls -f \{file}`"
    None => fallback_endpoint_suggestion(file)
  }
}

///|
fn schema_not_found_suggestion(
  name : String,
  content : String,
  file : String,
) -> String {
  match closest_schema_name(name, content) {
    Some(candidate) =>
      "did you mean '\{candidate}'? run `apispec schema get \{candidate} -f \{file}` or `apispec schema ls -f \{file}`"
    None => fallback_schema_suggestion(file)
  }
}

///|
fn closest_operation_id(target : String, content : String) -> String? {
  match
    @lib.list_endpoints_from_source(
      content,
      options=@lib.endpoint_list_options(None, None),
    ) {
    Ok(endpoints) =>
      closest_candidate(
        target,
        endpoints.map(endpoint => endpoint.operation_id),
      )
    Err(_) => None
  }
}

///|
fn closest_schema_name(name : String, content : String) -> String? {
  match @lib.list_schemas_from_source(content) {
    Ok(schemas) => closest_candidate(name, schemas.map(schema => schema.name))
    Err(_) => None
  }
}

///|
fn closest_candidate(target : String, candidates : Array[String]) -> String? {
  let normalized_target = target.to_lower()
  if normalized_target.is_empty() || candidates.length() == 0 {
    None
  } else {
    let mut best_candidate : String? = None
    let mut best_distance = 0
    let mut has_tie = false
    for candidate in candidates {
      let distance = edit_distance(normalized_target, candidate.to_lower())
      match best_candidate {
        None => {
          best_candidate = Some(candidate)
          best_distance = distance
          has_tie = false
        }
        Some(best) =>
          if distance < best_distance {
            best_candidate = Some(candidate)
            best_distance = distance
            has_tie = false
          } else if distance == best_distance && candidate != best {
            has_tie = true
          }
      }
    }
    let threshold = suggestion_distance_threshold(normalized_target.length())
    match best_candidate {
      Some(candidate) =>
        if !has_tie && best_distance <= threshold {
          Some(candidate)
        } else {
          None
        }
      None => None
    }
  }
}

///|
fn suggestion_distance_threshold(length : Int) -> Int {
  max_int(2, length / 3)
}

///|
fn edit_distance(left : String, right : String) -> Int {
  let left_len = left.length()
  let right_len = right.length()
  let mut previous : Array[Int] = []
  for j in 0..<=right_len {
    previous.push(j)
  }
  for i in 1..<=left_len {
    let current : Array[Int] = []
    current.push(i)
    for j in 1..<=right_len {
      let cost = if left[i - 1] == right[j - 1] { 0 } else { 1 }
      let deletion = previous[j] + 1
      let insertion = current[j - 1] + 1
      let substitution = previous[j - 1] + cost
      current.push(min_int(deletion, min_int(insertion, substitution)))
    }
    previous = current
  }
  previous[right_len]
}

///|
fn min_int(left : Int, right : Int) -> Int {
  if left < right {
    left
  } else {
    right
  }
}

///|
fn max_int(left : Int, right : Int) -> Int {
  if left > right {
    left
  } else {
    right
  }
}

///|
fn fallback_endpoint_suggestion(file : String) -> String {
  "run `apispec endpoint ls -f \{file}` to inspect available operations"
}

///|
fn fallback_schema_suggestion(file : String) -> String {
  "run `apispec schema ls -f \{file}` to inspect available schemas"
}
