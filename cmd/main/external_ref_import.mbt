///|
async fn import_external_ref(
  ref_value : String,
  current_document : Json,
  current_location : RefDocumentLocation,
  root : Map[String, Json],
  root_kind : RootSpecKind,
  ctx : ExternalRefContext,
) -> String? {
  let (document_ref, fragment) = match split_ref(ref_value) {
    Some(parts) => parts
    None => {
      warn_unsupported_external_ref(ctx, ref_value)
      return None
    }
  }
  let target_location = match
    resolve_ref_document_location(current_location, document_ref) {
    Some(location) => location
    None => {
      warn_unsupported_external_ref(ctx, ref_value)
      return None
    }
  }
  let document = if document_ref.is_empty() {
    current_document
  } else {
    match load_external_document(target_location, ref_value, ctx) {
      Some(document) => document
      None => return None
    }
  }
  let tokens = match decode_ref_fragment(fragment) {
    Some(tokens) => tokens
    None => {
      warn_unsupported_external_ref(ctx, ref_value)
      return None
    }
  }
  let target = match external_ref_target(tokens, root_kind) {
    Some(target) => target
    None => {
      warn_unsupported_external_ref(ctx, ref_value)
      return None
    }
  }
  let key = import_key(target_location, target.import_tokens)
  match ctx.imported.get(key) {
    Some(internal_ref) => Some(internal_ref)
    None =>
      match ctx.in_progress.get(key) {
        Some(internal_ref) => Some(internal_ref)
        None =>
          import_external_target(
            ref_value, key, document, target_location, target, root, root_kind, ctx,
          )
      }
  }
}

///|
fn warn_unsupported_external_ref(
  ctx : ExternalRefContext,
  ref_value : String,
) -> Unit {
  warn_external_once(ctx, ref_value, "unsupported external $ref: \{ref_value}")
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
  match @json_pointer.get(source_document, target.import_tokens) {
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
          reuse_existing_external_component(
            ref_value, key, component, existing, target, ctx,
          )
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
fn reuse_existing_external_component(
  ref_value : String,
  key : String,
  component : Json,
  existing : Json,
  target : ExternalRefTarget,
  ctx : ExternalRefContext,
) -> String? {
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
        rewritten[key] = rewrite_imported_object_entry(
          key, child, source_document, source_location, root, root_kind, ctx,
        )
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
async fn rewrite_imported_object_entry(
  key : String,
  child : Json,
  source_document : Json,
  source_location : RefDocumentLocation,
  root : Map[String, Json],
  root_kind : RootSpecKind,
  ctx : ExternalRefContext,
) -> Json {
  if key == "$ref" {
    rewrite_imported_ref(
      child, source_document, source_location, root, root_kind, ctx,
    )
  } else {
    rewrite_imported_component(
      child, source_document, source_location, root, root_kind, ctx,
    )
  }
}

///|
async fn rewrite_imported_ref(
  child : Json,
  source_document : Json,
  source_location : RefDocumentLocation,
  root : Map[String, Json],
  root_kind : RootSpecKind,
  ctx : ExternalRefContext,
) -> Json {
  match child {
    String(ref_value) =>
      match
        import_external_ref(
          ref_value, source_document, source_location, root, root_kind, ctx,
        ) {
        Some(internal_ref) => Json::string(internal_ref)
        None => child
      }
    _ => child
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
    None =>
      match read_external_document_content(location, ref_value, ctx) {
        None => None
        Some(content) =>
          match parse_external_document(content, ref_value, ctx) {
            None => None
            Some(document) => {
              ctx.cache[key] = document
              Some(document)
            }
          }
      }
  }
}

///|
async fn read_external_document_content(
  location : RefDocumentLocation,
  ref_value : String,
  ctx : ExternalRefContext,
) -> String? {
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
    Ok(content) => Some(content)
  }
}

///|
fn parse_external_document(
  content : String,
  ref_value : String,
  ctx : ExternalRefContext,
) -> Json? {
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
    Ok(document) => Some(document)
  }
}
