///|
async fn advance_external_ref_resolution(
  source : String,
  location : RefDocumentLocation,
  warnings : Array[String],
  accumulated : Array[String],
  blocked : Map[String, Bool],
) -> ExternalRefAdvance {
  let refs = unresolved_external_refs(warnings, blocked)
  if refs.length() == 0 {
    ExternalRefsResolved
  } else {
    let rewrite = rewrite_external_refs_once(source, location, refs)
    append_cli_warnings(accumulated, rewrite.warnings)
    mark_blocked_refs(blocked, rewrite.warnings)
    if rewrite.changed {
      ExternalRefsRewritten(rewrite.source)
    } else {
      ExternalRefsUnchanged
    }
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
