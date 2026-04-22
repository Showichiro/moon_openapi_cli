///|
pub fn endpoint_search_options(
  tag : String?,
  http_method : String?,
  limit : Int,
) -> EndpointSearchOptions {
  { tag, http_method, limit }
}

///|
pub fn schema_search_options(limit : Int) -> SchemaSearchOptions {
  { limit, }
}

///|
pub fn search_endpoints_from_source(
  source : String,
  query : String,
  options~ : EndpointSearchOptions,
) -> Result[Array[EndpointSearchResult], ApispecError] {
  match parse_json_object_source(source) {
    Ok(json) => search_endpoints(json, query, options~)
    Err(err) => Err(err)
  }
}

///|
pub fn search_endpoints(
  document : Json,
  query : String,
  options~ : EndpointSearchOptions,
) -> Result[Array[EndpointSearchResult], ApispecError] {
  match validate_search_input(query, options.limit) {
    Err(err) => Err(err)
    Ok(query) =>
      match
        list_endpoints(
          document,
          options=endpoint_list_options(options.tag, options.http_method),
        ) {
        Err(err) => Err(err)
        Ok(endpoints) =>
          Ok(score_endpoint_results(endpoints, query, options.limit))
      }
  }
}

///|
pub fn search_schemas_from_source(
  source : String,
  query : String,
  options~ : SchemaSearchOptions,
) -> Result[Array[SchemaSearchResult], ApispecError] {
  match parse_json_object_source(source) {
    Ok(json) => search_schemas(json, query, options~)
    Err(err) => Err(err)
  }
}

///|
pub fn search_schemas(
  document : Json,
  query : String,
  options~ : SchemaSearchOptions,
) -> Result[Array[SchemaSearchResult], ApispecError] {
  match validate_search_input(query, options.limit) {
    Err(err) => Err(err)
    Ok(query) =>
      match normalize_document(document) {
        Err(err) => Err(err)
        Ok(document) =>
          search_schemas_normalized(document, query, options.limit)
      }
  }
}

///|
fn validate_search_input(
  query : String,
  limit : Int,
) -> Result[String, ApispecError] {
  let query = query.trim().to_string()
  if query.is_empty() {
    Err(UsageError("expected non-empty search query"))
  } else if limit <= 0 {
    Err(UsageError("limit must be greater than 0"))
  } else {
    Ok(query)
  }
}

///|
fn score_endpoint_results(
  endpoints : Array[EndpointSummary],
  query : String,
  limit : Int,
) -> Array[EndpointSearchResult] {
  let scored : Array[EndpointSearchResult] = []
  let terms = build_search_terms(query)
  for endpoint in endpoints {
    let result = score_endpoint(endpoint, terms)
    if result.score > 0 {
      scored.push(result)
    }
  }
  sort_endpoint_search_results(scored)
  take_endpoint_search_results(scored, limit)
}

///|
fn score_endpoint(
  endpoint : EndpointSummary,
  terms : SearchTerms,
) -> EndpointSearchResult {
  let matched_fields : Array[String] = []
  let mut score = 0
  score += score_field(
    endpoint.operation_id,
    terms,
    "operationId",
    matched_fields,
    exact=120,
    phrase=80,
    token=24,
  )
  score += score_field(
    endpoint.http_method,
    terms,
    "method",
    matched_fields,
    exact=70,
    phrase=30,
    token=12,
  )
  score += score_field(
    endpoint.path,
    terms,
    "path",
    matched_fields,
    exact=90,
    phrase=60,
    token=18,
  )
  if endpoint.summary is Some(summary) {
    score += score_field(
      summary,
      terms,
      "summary",
      matched_fields,
      exact=90,
      phrase=55,
      token=16,
    )
  }
  for tag in endpoint.tags {
    score += score_field(
      tag,
      terms,
      "tags",
      matched_fields,
      exact=80,
      phrase=45,
      token=12,
    )
  }
  score += coverage_bonus(
    terms,
    count_matched_groups(endpoint_search_values(endpoint), terms),
  )
  {
    operation_id: endpoint.operation_id,
    target: endpoint_target(endpoint.http_method, endpoint.path),
    http_method: endpoint.http_method,
    path: endpoint.path,
    tags: endpoint.tags,
    summary: endpoint.summary,
    score,
    matched_fields,
  }
}

///|
fn search_schemas_normalized(
  document : Json,
  query : String,
  limit : Int,
) -> Result[Array[SchemaSearchResult], ApispecError] {
  match document {
    Object(root) =>
      match extract_schema_map(root) {
        Err(err) => Err(err)
        Ok(schemas) => {
          let results : Array[SchemaSearchResult] = []
          let terms = build_search_terms(query)
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
  terms : SearchTerms,
) -> SchemaSearchResult {
  let summary = schema_summary(name, schema)
  let matched_fields : Array[String] = []
  let mut score = 0
  score += score_field(
    summary.name,
    terms,
    "name",
    matched_fields,
    exact=120,
    phrase=80,
    token=24,
  )
  if summary.title is Some(title) {
    score += score_field(
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
    score += score_field(
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
        score += score_field(
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
          score += score_field(
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
  score += coverage_bonus(
    terms,
    count_matched_groups(schema_search_values(summary, schema), terms),
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
fn endpoint_target(http_method : String, path : String) -> String {
  "\{http_method} \{path}"
}

///|
fn endpoint_search_values(endpoint : EndpointSummary) -> Array[String] {
  let values : Array[String] = [
    endpoint.operation_id,
    endpoint.http_method,
    endpoint.path,
  ]
  if endpoint.summary is Some(summary) {
    values.push(summary)
  }
  for tag in endpoint.tags {
    values.push(tag)
  }
  values
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
priv struct SearchTermGroup {
  alternatives : Array[String]
}

///|
priv struct SearchTerms {
  phrase : String
  tokens : Array[String]
  groups : Array[SearchTermGroup]
}

///|
fn build_search_terms(query : String) -> SearchTerms {
  let phrase = normalize_search_text(query)
  let tokens : Array[String] = []
  let groups : Array[SearchTermGroup] = []
  for view in phrase.split(" ") {
    let token = view.to_string()
    if !token.is_empty() {
      let alternatives : Array[String] = []
      add_unique_token(alternatives, token)
      add_query_aliases(alternatives, token)
      for alternative in alternatives {
        add_unique_token(tokens, alternative)
      }
      groups.push({ alternatives, })
    }
  }
  { phrase, tokens, groups }
}

///|
fn add_query_aliases(tokens : Array[String], token : String) -> Unit {
  match token {
    "create" => {
      add_unique_token(tokens, "add")
      add_unique_token(tokens, "post")
      add_unique_token(tokens, "new")
    }
    "add" => {
      add_unique_token(tokens, "create")
      add_unique_token(tokens, "post")
      add_unique_token(tokens, "new")
    }
    "new" => {
      add_unique_token(tokens, "create")
      add_unique_token(tokens, "add")
    }
    "remove" => add_unique_token(tokens, "delete")
    "delete" => add_unique_token(tokens, "remove")
    "list" => add_unique_token(tokens, "get")
    "fetch" => add_unique_token(tokens, "get")
    "read" => add_unique_token(tokens, "get")
    _ => ()
  }
}

///|
fn add_unique_token(tokens : Array[String], token : String) -> Unit {
  if !token.is_empty() && !tokens.contains(token) {
    tokens.push(token)
  }
}

///|
fn count_matched_groups(values : Array[String], terms : SearchTerms) -> Int {
  let normalized_values = values.map(value => normalize_search_text(value))
  let mut matched = 0
  for group in terms.groups {
    if group_matches(normalized_values, group) {
      matched += 1
    }
  }
  matched
}

///|
fn group_matches(
  normalized_values : Array[String],
  group : SearchTermGroup,
) -> Bool {
  let mut found = false
  for term in group.alternatives {
    for value in normalized_values {
      if value.contains(term) {
        found = true
      }
    }
  }
  found
}

///|
fn coverage_bonus(terms : SearchTerms, matched : Int) -> Int {
  let total = terms.groups.length()
  if total == 0 {
    0
  } else if matched == total {
    100 + total * 8
  } else if matched >= 2 {
    40
  } else {
    0
  }
}

///|
fn score_field(
  value : String,
  terms : SearchTerms,
  field : String,
  matched_fields : Array[String],
  exact~ : Int,
  phrase~ : Int,
  token~ : Int,
) -> Int {
  let text = normalize_search_text(value)
  let mut score = 0
  if text == terms.phrase {
    score += exact
  } else if !terms.phrase.is_empty() && text.contains(terms.phrase) {
    score += phrase
  }
  for term in terms.tokens {
    if text.contains(term) {
      score += token
    }
  }
  if score > 0 && !matched_fields.contains(field) {
    matched_fields.push(field)
  }
  score
}

///|
fn normalize_search_text(value : String) -> String {
  value
  .insert_ascii_word_boundaries()
  .to_lower()
  .replace_all(old="/", new=" ")
  .replace_all(old="{", new=" ")
  .replace_all(old="}", new=" ")
  .replace_all(old="_", new=" ")
  .replace_all(old="-", new=" ")
  .replace_all(old=".", new=" ")
  .replace_all(old=",", new=" ")
  .replace_all(old=":", new=" ")
  .replace_all(old=";", new=" ")
  .replace_all(old="(", new=" ")
  .replace_all(old=")", new=" ")
  .replace_all(old="[", new=" ")
  .replace_all(old="]", new=" ")
  .trim()
  .to_string()
}

///|
fn String::insert_ascii_word_boundaries(self : String) -> String {
  let buf = StringBuilder::new()
  let mut previous_is_word = false
  let mut previous_is_lower_or_digit = false
  for char in self {
    if is_ascii_upper(char) && previous_is_word && previous_is_lower_or_digit {
      buf.write_char(' ')
    }
    buf.write_char(char)
    previous_is_word = is_ascii_alnum(char)
    previous_is_lower_or_digit = is_ascii_lower(char) || is_ascii_digit(char)
  }
  buf.to_string()
}

///|
fn is_ascii_upper(char : Char) -> Bool {
  match char {
    'A'..='Z' => true
    _ => false
  }
}

///|
fn is_ascii_lower(char : Char) -> Bool {
  match char {
    'a'..='z' => true
    _ => false
  }
}

///|
fn is_ascii_digit(char : Char) -> Bool {
  match char {
    '0'..='9' => true
    _ => false
  }
}

///|
fn is_ascii_alnum(char : Char) -> Bool {
  is_ascii_lower(char) || is_ascii_upper(char) || is_ascii_digit(char)
}

///|
fn sort_endpoint_search_results(results : Array[EndpointSearchResult]) -> Unit {
  results.sort_by((left, right) => {
    let score_cmp = right.score - left.score
    if score_cmp != 0 {
      score_cmp
    } else {
      let path_cmp = left.path.lexical_compare(right.path)
      if path_cmp != 0 {
        path_cmp
      } else {
        let method_cmp = method_rank(left.http_method) -
          method_rank(right.http_method)
        if method_cmp != 0 {
          method_cmp
        } else {
          left.operation_id.lexical_compare(right.operation_id)
        }
      }
    }
  })
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
fn take_endpoint_search_results(
  results : Array[EndpointSearchResult],
  limit : Int,
) -> Array[EndpointSearchResult] {
  if results.length() <= limit {
    results
  } else {
    let limited : Array[EndpointSearchResult] = []
    for index in 0..<limit {
      limited.push(results[index])
    }
    limited
  }
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
