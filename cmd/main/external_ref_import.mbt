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
