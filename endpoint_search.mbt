///|
fn score_endpoint_results(
  endpoints : Array[EndpointSummary],
  query : String,
  limit : Int,
) -> Array[EndpointSearchResult] {
  let scored : Array[EndpointSearchResult] = []
  let terms = @search.build_search_terms(query)
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
  terms : @search.SearchTerms,
) -> EndpointSearchResult {
  let matched_fields : Array[String] = []
  let mut score = 0
  score += @search.score_field(
    endpoint.operation_id,
    terms,
    "operationId",
    matched_fields,
    exact=120,
    phrase=80,
    token=24,
  )
  score += @search.score_field(
    endpoint.http_method,
    terms,
    "method",
    matched_fields,
    exact=70,
    phrase=30,
    token=12,
  )
  score += @search.score_field(
    endpoint.path,
    terms,
    "path",
    matched_fields,
    exact=90,
    phrase=60,
    token=18,
  )
  if endpoint.summary is Some(summary) {
    score += @search.score_field(
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
    score += @search.score_field(
      tag,
      terms,
      "tags",
      matched_fields,
      exact=80,
      phrase=45,
      token=12,
    )
  }
  score += @search.coverage_bonus(
    terms,
    @search.count_matched_groups(endpoint_search_values(endpoint), terms),
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
