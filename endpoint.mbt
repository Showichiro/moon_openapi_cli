///|
pub using @endpoint {
  type EndpointGetFormat,
  type EndpointGetOptions,
  type EndpointListFormat,
  type EndpointListOptions,
  type EndpointSearchFormat,
  type EndpointSearchOptions,
  type EndpointSearchResult,
  type EndpointSubset,
  type EndpointSummary,
}

///|
pub fn endpoint_list_options(
  tag : String?,
  http_method : String?,
) -> EndpointListOptions {
  @endpoint.endpoint_list_options(tag, http_method)
}

///|
pub fn endpoint_get_options(no_resolve : Bool) -> EndpointGetOptions {
  @endpoint.endpoint_get_options(no_resolve)
}

///|
pub fn endpoint_search_options(
  tag : String?,
  http_method : String?,
  limit : Int,
) -> EndpointSearchOptions {
  @endpoint.endpoint_search_options(tag, http_method, limit)
}

///|
pub fn list_endpoints_from_source(
  source : String,
  options~ : EndpointListOptions,
) -> Result[Array[EndpointSummary], ApispecError] {
  @endpoint.list_endpoints_from_source(source, options~)
}

///|
pub fn list_endpoints(
  document : Json,
  options~ : EndpointListOptions,
) -> Result[Array[EndpointSummary], ApispecError] {
  @endpoint.list_endpoints(document, options~)
}

///|
pub fn get_endpoint_from_source(
  source : String,
  target : String,
  options~ : EndpointGetOptions,
) -> Result[EndpointSubset, ApispecError] {
  @endpoint.get_endpoint_from_source(source, target, options~)
}

///|
pub fn get_endpoint(
  document : Json,
  target : String,
  options~ : EndpointGetOptions,
) -> Result[EndpointSubset, ApispecError] {
  @endpoint.get_endpoint(document, target, options~)
}

///|
pub fn search_endpoints_from_source(
  source : String,
  query : String,
  options~ : EndpointSearchOptions,
) -> Result[Array[EndpointSearchResult], ApispecError] {
  @endpoint.search_endpoints_from_source(source, query, options~)
}

///|
pub fn search_endpoints(
  document : Json,
  query : String,
  options~ : EndpointSearchOptions,
) -> Result[Array[EndpointSearchResult], ApispecError] {
  @endpoint.search_endpoints(document, query, options~)
}

///|
pub fn format_endpoint_list(
  endpoints : Array[EndpointSummary],
  format : EndpointListFormat,
) -> String {
  @endpoint.format_endpoint_list(endpoints, format)
}

///|
pub fn format_endpoint_search_results(
  results : Array[EndpointSearchResult],
  format : EndpointSearchFormat,
) -> String {
  @endpoint.format_endpoint_search_results(results, format)
}

///|
pub fn format_endpoint_subset(
  subset : EndpointSubset,
  format : EndpointGetFormat,
) -> String {
  @endpoint.format_endpoint_subset(subset, format)
}
