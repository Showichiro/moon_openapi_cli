///|
fn search_schemas_normalized(
  document : Json,
  query : String,
  limit : Int,
) -> Result[Array[SchemaSearchResult], ApispecError] {
  match document {
    Object(root) =>
      match @schema_metadata.extract_schema_map(root) {
        Err(err) => Err(err)
        Ok(schemas) => {
          let results : Array[SchemaSearchResult] = []
          let terms = @search.build_search_terms(query)
          for name, schema in schemas {
            let result = score_schema(name, schema, terms)
            if result.score > 0 {
              results.push(result)
            }
          }
          sort_schema_search_results(results)
          Ok(take_schema_search_results(results, limit))
        }
      }
    _ => Err(ParseError("expected JSON object input"))
  }
}

///|
fn score_schema(
  name : String,
  schema : Json,
  terms : @search.SearchTerms,
) -> SchemaSearchResult {
  let summary = schema_summary(name, schema)
  let matched_fields : Array[String] = []
  let mut score = 0
  score += @search.score_field(
    summary.name,
    terms,
    "name",
    matched_fields,
    exact=120,
    phrase=80,
    token=24,
  )
  if summary.title is Some(title) {
    score += @search.score_field(
      title,
      terms,
      "title",
      matched_fields,
      exact=90,
      phrase=55,
      token=16,
    )
  }
  if summary.schema_type is Some(schema_type) {
    score += @search.score_field(
      schema_type,
      terms,
      "type",
      matched_fields,
      exact=70,
      phrase=35,
      token=10,
    )
  }
  if schema is Object(object) {
    match object.get("description") {
      Some(String(description)) =>
        score += @search.score_field(
          description,
          terms,
          "description",
          matched_fields,
          exact=70,
          phrase=40,
          token=12,
        )
      _ => ()
    }
    match object.get("properties") {
      Some(Object(properties)) =>
        for property, _ in properties {
          score += @search.score_field(
            property,
            terms,
            "properties",
            matched_fields,
            exact=40,
            phrase=20,
            token=5,
          )
        }
      _ => ()
    }
  }
  score += @search.coverage_bonus(
    terms,
    @search.count_matched_groups(schema_search_values(summary, schema), terms),
  )
  if matched_fields.length() == 1 && matched_fields[0] == "properties" {
    score = score / 2
  }
  {
    name: summary.name,
    title: summary.title,
    schema_type: summary.schema_type,
    score,
    matched_fields,
  }
}

///|
fn schema_search_values(
  summary : SchemaSummary,
  schema : Json,
) -> Array[String] {
  let values : Array[String] = [summary.name]
  if summary.title is Some(title) {
    values.push(title)
  }
  if summary.schema_type is Some(schema_type) {
    values.push(schema_type)
  }
  if schema is Object(object) {
    match object.get("description") {
      Some(String(description)) => values.push(description)
      _ => ()
    }
    match object.get("properties") {
      Some(Object(properties)) =>
        for property, _ in properties {
          values.push(property)
        }
      _ => ()
    }
  }
  values
}

///|
fn sort_schema_search_results(results : Array[SchemaSearchResult]) -> Unit {
  results.sort_by((left, right) => {
    let score_cmp = right.score - left.score
    if score_cmp != 0 {
      score_cmp
    } else {
      left.name.lexical_compare(right.name)
    }
  })
}

///|
fn take_schema_search_results(
  results : Array[SchemaSearchResult],
  limit : Int,
) -> Array[SchemaSearchResult] {
  if results.length() <= limit {
    results
  } else {
    let limited : Array[SchemaSearchResult] = []
    for index in 0..<limit {
      limited.push(results[index])
    }
    limited
  }
}
