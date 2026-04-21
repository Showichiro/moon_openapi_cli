///|
priv struct ResolvedEndpointExtraction {
  subset : @lib.EndpointSubset
  warnings : Array[String]
}

///|
priv struct ResolvedSchemaExtraction {
  subset : @lib.SchemaSubset
  warnings : Array[String]
}

///|
priv enum RefDocumentLocation {
  NoRefDocument
  LocalRefDocument(String)
  RemoteRefDocument(String)
}

///|
priv enum RootSpecKind {
  RootOpenApi
  RootSwagger2
}

///|
priv struct ExternalRefRewrite {
  source : String
  warnings : Array[String]
  changed : Bool
}

///|
priv struct ExternalRefContext {
  cache : Map[String, Json]
  warnings : Array[String]
  warned : Map[String, Bool]
  imported : Map[String, String]
  in_progress : Map[String, String]
  mut changed : Bool
}

///|
priv struct ExternalRefTarget {
  import_tokens : Array[String]
  insert_container : String
  section : String
  name : String
  internal_ref : String
}

///|
const EXTERNAL_REF_MAX_PASSES : Int = 8

///|
async fn resolve_endpoint_with_external_refs(
  source : String,
  input : String,
  target : String,
  options : @lib.EndpointGetOptions,
) -> Result[ResolvedEndpointExtraction, @lib.ApispecError] {
  if options.no_resolve {
    match @lib.get_endpoint_from_source(source, target, options~) {
      Err(err) => Err(err)
      Ok(subset) => Ok({ subset, warnings: subset.warnings })
    }
  } else {
    let location = ref_location_from_input(input)
    let accumulated : Array[String] = []
    let blocked : Map[String, Bool] = {}
    let mut current = source
    for _ in 0..<EXTERNAL_REF_MAX_PASSES {
      match @lib.get_endpoint_from_source(current, target, options~) {
        Err(err) => return Err(err)
        Ok(subset) => {
          let refs = unresolved_external_refs(subset.warnings, blocked)
          if refs.length() == 0 {
            return Ok({
              subset,
              warnings: merge_cli_warnings(accumulated, subset.warnings),
            })
          }
          let rewrite = rewrite_external_refs_once(current, location, refs)
          append_cli_warnings(accumulated, rewrite.warnings)
          mark_blocked_refs(blocked, rewrite.warnings)
          if rewrite.changed {
            current = rewrite.source
          } else {
            return Ok({
              subset,
              warnings: merge_cli_warnings(accumulated, subset.warnings),
            })
          }
        }
      }
    }
    match @lib.get_endpoint_from_source(current, target, options~) {
      Err(err) => Err(err)
      Ok(subset) => {
        accumulated.push(
          "external $ref resolution stopped: maximum pass count reached",
        )
        Ok({
          subset,
          warnings: merge_cli_warnings(accumulated, subset.warnings),
        })
      }
    }
  }
}

///|
async fn resolve_schema_with_external_refs(
  source : String,
  input : String,
  name : String,
  options : @lib.SchemaGetOptions,
) -> Result[ResolvedSchemaExtraction, @lib.ApispecError] {
  let location = ref_location_from_input(input)
  let accumulated : Array[String] = []
  let blocked : Map[String, Bool] = {}
  let mut current = source
  for _ in 0..<EXTERNAL_REF_MAX_PASSES {
    match @lib.get_schema_from_source(current, name, options~) {
      Err(err) => return Err(err)
      Ok(subset) => {
        let refs = unresolved_external_refs(subset.warnings, blocked)
        if refs.length() == 0 {
          return Ok({
            subset,
            warnings: merge_cli_warnings(accumulated, subset.warnings),
          })
        }
        let rewrite = rewrite_external_refs_once(current, location, refs)
        append_cli_warnings(accumulated, rewrite.warnings)
        mark_blocked_refs(blocked, rewrite.warnings)
        if rewrite.changed {
          current = rewrite.source
        } else {
          return Ok({
            subset,
            warnings: merge_cli_warnings(accumulated, subset.warnings),
          })
        }
      }
    }
  }
  match @lib.get_schema_from_source(current, name, options~) {
    Err(err) => Err(err)
    Ok(subset) => {
      accumulated.push(
        "external $ref resolution stopped: maximum pass count reached",
      )
      Ok({ subset, warnings: merge_cli_warnings(accumulated, subset.warnings) })
    }
  }
}

///|
fn ref_location_from_input(input : String) -> RefDocumentLocation {
  match classify_input_source(input) {
    Stdin => NoRefDocument
    LocalFile(path) => LocalRefDocument(normalize_path(path))
    RemoteUrl(url) => RemoteRefDocument(url)
    UnsupportedUrl(_) => NoRefDocument
  }
}

///|
fn unresolved_external_refs(
  warnings : Array[String],
  blocked : Map[String, Bool],
) -> Array[String] {
  let refs : Array[String] = []
  for warning in warnings {
    if warning.has_prefix(UNSUPPORTED_EXTERNAL_REF_PREFIX) {
      let ref_value = warning[UNSUPPORTED_EXTERNAL_REF_PREFIX.length():].to_string()
      if !blocked.contains(ref_value) && !refs.contains(ref_value) {
        refs.push(ref_value)
      }
    }
  }
  refs
}

///|
async fn rewrite_external_refs_once(
  source : String,
  root_location : RefDocumentLocation,
  refs : Array[String],
) -> ExternalRefRewrite {
  let parsed : Result[Json, _] = try? @json.parse(source)
  match parsed {
    Err(_) => { source, warnings: [], changed: false }
    Ok(document) =>
      match document {
        Object(root) => {
          let ctx = new_external_ref_context()
          let root_kind = detect_root_spec_kind(root)
          let rewrites : Map[String, String] = {}
          for ref_value in refs {
            match
              import_external_ref(
                ref_value, document, root_location, root, root_kind, ctx,
              ) {
              Some(internal_ref) => rewrites[ref_value] = internal_ref
              None => ()
            }
          }
          if !rewrites.is_empty() {
            replace_refs_in_place(document, rewrites)
          }
          {
            source: if ctx.changed {
              document.stringify()
            } else {
              source
            },
            warnings: ctx.warnings,
            changed: ctx.changed,
          }
        }
        _ => { source, warnings: [], changed: false }
      }
  }
}

///|
fn new_external_ref_context() -> ExternalRefContext {
  {
    cache: {},
    warnings: [],
    warned: {},
    imported: {},
    in_progress: {},
    changed: false,
  }
}

///|
fn detect_root_spec_kind(root : Map[String, Json]) -> RootSpecKind {
  match root.get("swagger") {
    Some(String("2.0")) => RootSwagger2
    _ => RootOpenApi
  }
}

///|
async fn import_external_ref(
  ref_value : String,
  current_document : Json,
  current_location : RefDocumentLocation,
  root : Map[String, Json],
  root_kind : RootSpecKind,
  ctx : ExternalRefContext,
) -> String? {
  match split_ref(ref_value) {
    None => {
      warn_external_once(
        ctx,
        ref_value,
        "unsupported external $ref: \{ref_value}",
      )
      None
    }
    Some((document_ref, fragment)) =>
      match resolve_ref_document_location(current_location, document_ref) {
        None => {
          warn_external_once(
            ctx,
            ref_value,
            "unsupported external $ref: \{ref_value}",
          )
          None
        }
        Some(target_location) => {
          let target_document = if document_ref.is_empty() {
            Some(current_document)
          } else {
            load_external_document(target_location, ref_value, ctx)
          }
          match target_document {
            None => None
            Some(document) =>
              match decode_ref_fragment(fragment) {
                None => {
                  warn_external_once(
                    ctx,
                    ref_value,
                    "unsupported external $ref: \{ref_value}",
                  )
                  None
                }
                Some(tokens) =>
                  match external_ref_target(tokens, root_kind) {
                    None => {
                      warn_external_once(
                        ctx,
                        ref_value,
                        "unsupported external $ref: \{ref_value}",
                      )
                      None
                    }
                    Some(target) => {
                      let key = import_key(
                        target_location,
                        target.import_tokens,
                      )
                      match ctx.imported.get(key) {
                        Some(internal_ref) => Some(internal_ref)
                        None =>
                          match ctx.in_progress.get(key) {
                            Some(internal_ref) => Some(internal_ref)
                            None =>
                              import_external_target(
                                ref_value, key, document, target_location, target,
                                root, root_kind, ctx,
                              )
                          }
                      }
                    }
                  }
              }
          }
        }
      }
  }
}

///|
async fn import_external_target(
  ref_value : String,
  key : String,
  source_document : Json,
  source_location : RefDocumentLocation,
  target : ExternalRefTarget,
  root : Map[String, Json],
  root_kind : RootSpecKind,
  ctx : ExternalRefContext,
) -> String? {
  match get_json_pointer_for_external(source_document, target.import_tokens) {
    None => {
      warn_external_once(
        ctx,
        ref_value,
        "external $ref pointer not found: \{ref_value}",
      )
      None
    }
    Some(component) =>
      match root_component(root, target) {
        Some(existing) =>
          if existing.stringify() == component.stringify() {
            ctx.imported[key] = target.internal_ref
            Some(target.internal_ref)
          } else {
            warn_external_once(
              ctx,
              ref_value,
              "external $ref conflict: \{ref_value} -- target already exists",
            )
            None
          }
        None => {
          ctx.in_progress[key] = target.internal_ref
          let rewritten = rewrite_imported_component(
            component, source_document, source_location, root, root_kind, ctx,
          )
          if insert_root_component(root, target, rewritten) {
            ctx.imported[key] = target.internal_ref
            ctx.changed = true
            Some(target.internal_ref)
          } else {
            warn_external_once(
              ctx,
              ref_value,
              "external $ref conflict: \{ref_value} -- target container is not an object",
            )
            None
          }
        }
      }
  }
}

///|
async fn rewrite_imported_component(
  value : Json,
  source_document : Json,
  source_location : RefDocumentLocation,
  root : Map[String, Json],
  root_kind : RootSpecKind,
  ctx : ExternalRefContext,
) -> Json {
  match value {
    Object(object) => {
      let rewritten : Map[String, Json] = {}
      for key, child in object {
        if key == "$ref" {
          match child {
            String(ref_value) =>
              match
                import_external_ref(
                  ref_value, source_document, source_location, root, root_kind, ctx,
                ) {
                Some(internal_ref) =>
                  rewritten[key] = Json::string(internal_ref)
                None => rewritten[key] = child
              }
            _ => rewritten[key] = child
          }
        } else {
          rewritten[key] = rewrite_imported_component(
            child, source_document, source_location, root, root_kind, ctx,
          )
        }
      }
      Json::object(rewritten)
    }
    Array(items) => {
      let rewritten : Array[Json] = []
      for item in items {
        rewritten.push(
          rewrite_imported_component(
            item, source_document, source_location, root, root_kind, ctx,
          ),
        )
      }
      Json::array(rewritten)
    }
    _ => value
  }
}

///|
async fn load_external_document(
  location : RefDocumentLocation,
  ref_value : String,
  ctx : ExternalRefContext,
) -> Json? {
  let key = location_key(location)
  match ctx.cache.get(key) {
    Some(document) => Some(document)
    None => {
      let content_result = match location {
        LocalRefDocument(path) => read_file(path)
        RemoteRefDocument(url) => fetch_url(url)
        NoRefDocument => Err("missing external $ref base")
      }
      match content_result {
        Err(message) => {
          warn_external_once(
            ctx,
            ref_value,
            "external $ref load failed: \{ref_value} -- \{message}",
          )
          None
        }
        Ok(content) => {
          let parsed : Result[Json, _] = try? @json.parse(content)
          match parsed {
            Err(err) => {
              warn_external_once(
                ctx,
                ref_value,
                "external $ref parse failed: \{ref_value} -- \{err}",
              )
              None
            }
            Ok(document) => {
              ctx.cache[key] = document
              Some(document)
            }
          }
        }
      }
    }
  }
}

///|
fn split_ref(ref_value : String) -> (String, String)? {
  match ref_value.split_once("#") {
    Some((document_ref, fragment)) =>
      Some((document_ref.to_string(), fragment.to_string()))
    None => None
  }
}

///|
fn decode_ref_fragment(fragment : String) -> Array[String]? {
  if !fragment.has_prefix("/") {
    None
  } else {
    Some(fragment[1:].split("/").map(decode_external_pointer_token).collect())
  }
}

///|
fn decode_external_pointer_token(token : StringView) -> String {
  token
  .replace_all(old="~1", new="/")
  .replace_all(old="~0", new="~")
  .to_string()
}

///|
fn external_ref_target(
  tokens : Array[String],
  root_kind : RootSpecKind,
) -> ExternalRefTarget? {
  if tokens.length() >= 3 && tokens[0] == "components" {
    let section = tokens[1]
    let name = tokens[2]
    Some({
      import_tokens: ["components", section, name],
      insert_container: "components",
      section,
      name,
      internal_ref: encode_internal_ref(tokens),
    })
  } else if tokens.length() >= 2 && tokens[0] == "definitions" {
    let name = tokens[1]
    match root_kind {
      RootSwagger2 =>
        Some({
          import_tokens: ["definitions", name],
          insert_container: "definitions",
          section: "schemas",
          name,
          internal_ref: encode_internal_ref(tokens),
        })
      RootOpenApi => {
        let rewritten_tokens : Array[String] = ["components", "schemas", name]
        for token in tokens[2:] {
          rewritten_tokens.push(token)
        }
        Some({
          import_tokens: ["definitions", name],
          insert_container: "components",
          section: "schemas",
          name,
          internal_ref: encode_internal_ref(rewritten_tokens),
        })
      }
    }
  } else {
    None
  }
}

///|
fn encode_internal_ref(tokens : Array[String]) -> String {
  "#/" + tokens.map(encode_pointer_token).join("/")
}

///|
fn encode_pointer_token(token : String) -> String {
  token.replace_all(old="~", new="~0").replace_all(old="/", new="~1")
}

///|
fn resolve_ref_document_location(
  current : RefDocumentLocation,
  document_ref : String,
) -> RefDocumentLocation? {
  if document_ref.is_empty() {
    match current {
      NoRefDocument => None
      _ => Some(current)
    }
  } else if document_ref.has_prefix("http://") ||
    document_ref.has_prefix("https://") {
    Some(RemoteRefDocument(document_ref))
  } else if document_ref.find("://") is Some(_) {
    None
  } else {
    match current {
      NoRefDocument => None
      LocalRefDocument(path) =>
        Some(LocalRefDocument(resolve_local_ref(path, document_ref)))
      RemoteRefDocument(url) =>
        Some(RemoteRefDocument(resolve_remote_ref(url, document_ref)))
    }
  }
}

///|
fn resolve_local_ref(base_file : String, document_ref : String) -> String {
  if document_ref.has_prefix("/") {
    normalize_path(document_ref)
  } else {
    let base_dir = local_dirname(base_file)
    if base_dir == "." {
      normalize_path(document_ref)
    } else {
      normalize_path(base_dir + "/" + document_ref)
    }
  }
}

///|
fn resolve_remote_ref(base_url : String, document_ref : String) -> String {
  let clean_base = strip_url_suffix(base_url)
  if document_ref.has_prefix("/") {
    remote_origin(clean_base) + normalize_path(document_ref)
  } else {
    normalize_url_path(remote_dirname(clean_base) + document_ref)
  }
}

///|
fn strip_url_suffix(url : String) -> String {
  match url.split_once("#") {
    Some((base, _)) => base.to_string()
    None =>
      match url.split_once("?") {
        Some((base, _)) => base.to_string()
        None => url
      }
  }
}

///|
fn remote_origin(url : String) -> String {
  match url.find("://") {
    None => ""
    Some(scheme_end) => {
      let host_start = scheme_end + 3
      let rest = url[host_start:]
      match rest.find("/") {
        None => url
        Some(path_start) => url[:host_start + path_start].to_string()
      }
    }
  }
}

///|
fn remote_dirname(url : String) -> String {
  let origin = remote_origin(url)
  let path = url[origin.length():].to_string()
  let dir = local_dirname(path)
  if dir == "." {
    origin + "/"
  } else if dir == "/" {
    origin + "/"
  } else {
    origin + dir + "/"
  }
}

///|
fn normalize_url_path(url : String) -> String {
  let origin = remote_origin(url)
  if origin.is_empty() {
    normalize_path(url)
  } else {
    let path = url[origin.length():].to_string()
    origin + normalize_path(path)
  }
}

///|
fn local_dirname(path : String) -> String {
  let parts : Array[String] = path
    .split("/")
    .map(part => part.to_string())
    .collect()
  if parts.length() <= 1 {
    "."
  } else {
    let dir_parts = parts[:parts.length() - 1]
    if dir_parts.length() == 1 && dir_parts[0].is_empty() {
      "/"
    } else if dir_parts.length() == 0 {
      "."
    } else {
      dir_parts.join("/")
    }
  }
}

///|
fn normalize_path(path : String) -> String {
  let absolute = path.has_prefix("/")
  let stack : Array[String] = []
  for view in path.split("/") {
    let part = view.to_string()
    if part.is_empty() || part == "." {
      ()
    } else if part == ".." {
      if stack.length() > 0 && stack[stack.length() - 1] != ".." {
        let _ = stack.pop()
      } else if !absolute {
        stack.push(part)
      }
    } else {
      stack.push(part)
    }
  }
  let normalized = stack.join("/")
  if absolute {
    "/" + normalized
  } else if normalized.is_empty() {
    "."
  } else {
    normalized
  }
}

///|
fn location_key(location : RefDocumentLocation) -> String {
  match location {
    NoRefDocument => "none:"
    LocalRefDocument(path) => "file:\{path}"
    RemoteRefDocument(url) => "url:\{url}"
  }
}

///|
fn import_key(location : RefDocumentLocation, tokens : Array[String]) -> String {
  location_key(location) + "#" + tokens.join("/")
}

///|
fn root_component(
  root : Map[String, Json],
  target : ExternalRefTarget,
) -> Json? {
  match target.insert_container {
    "definitions" =>
      match root.get("definitions") {
        Some(Object(definitions)) => definitions.get(target.name)
        _ => None
      }
    _ =>
      match root.get("components") {
        Some(Object(components)) =>
          match components.get(target.section) {
            Some(Object(section)) => section.get(target.name)
            _ => None
          }
        _ => None
      }
  }
}

///|
fn insert_root_component(
  root : Map[String, Json],
  target : ExternalRefTarget,
  component : Json,
) -> Bool {
  match target.insert_container {
    "definitions" =>
      match ensure_object_property(root, "definitions") {
        None => false
        Some(definitions) => {
          definitions[target.name] = component
          true
        }
      }
    _ =>
      match ensure_object_property(root, "components") {
        None => false
        Some(components) =>
          match ensure_object_property(components, target.section) {
            None => false
            Some(section) => {
              section[target.name] = component
              true
            }
          }
      }
  }
}

///|
fn ensure_object_property(
  object : Map[String, Json],
  key : String,
) -> Map[String, Json]? {
  match object.get(key) {
    Some(Object(child)) => Some(child)
    Some(_) => None
    None => {
      let child : Map[String, Json] = {}
      object[key] = Json::object(child)
      Some(child)
    }
  }
}

///|
fn replace_refs_in_place(value : Json, rewrites : Map[String, String]) -> Unit {
  match value {
    Object(object) => {
      match object.get("$ref") {
        Some(String(ref_value)) =>
          match rewrites.get(ref_value) {
            Some(internal_ref) => object["$ref"] = Json::string(internal_ref)
            None => ()
          }
        _ => ()
      }
      for _, child in object {
        replace_refs_in_place(child, rewrites)
      }
    }
    Array(items) =>
      for item in items {
        replace_refs_in_place(item, rewrites)
      }
    _ => ()
  }
}

///|
fn get_json_pointer_for_external(
  document : Json,
  tokens : Array[String],
) -> Json? {
  let mut current = document
  for token in tokens {
    match current {
      Object(object) =>
        match object.get(token) {
          Some(next) => current = next
          None => return None
        }
      Array(items) =>
        match parse_array_index_for_external(token, items.length()) {
          Some(index) => current = items[index]
          None => return None
        }
      _ => return None
    }
  }
  Some(current)
}

///|
fn parse_array_index_for_external(token : String, length : Int) -> Int? {
  let parsed : Result[Int, _] = try? @string.parse_int(token)
  match parsed {
    Ok(index) => if index >= 0 && index < length { Some(index) } else { None }
    Err(_) => None
  }
}

///|
fn warn_external_once(
  ctx : ExternalRefContext,
  ref_value : String,
  message : String,
) -> Unit {
  let key = ref_value + "\n" + message
  if !ctx.warned.contains(key) {
    ctx.warned[key] = true
    ctx.warnings.push(message)
  }
}

///|
fn merge_cli_warnings(
  left : Array[String],
  right : Array[String],
) -> Array[String] {
  let merged : Array[String] = []
  append_cli_warnings(merged, left)
  append_cli_warnings(merged, right)
  merged
}

///|
fn append_cli_warnings(
  target : Array[String],
  warnings : Array[String],
) -> Unit {
  for warning in warnings {
    if !target.contains(warning) {
      target.push(warning)
    }
  }
}

///|
fn mark_blocked_refs(
  blocked : Map[String, Bool],
  warnings : Array[String],
) -> Unit {
  for warning in warnings {
    match warning_ref(warning) {
      Some(ref_value) => blocked[ref_value] = true
      None => ()
    }
  }
}
