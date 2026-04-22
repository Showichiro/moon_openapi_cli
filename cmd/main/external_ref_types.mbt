///|
priv struct ResolvedExtraction[Subset] {
  subset : Subset
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
priv enum ExternalRefAdvance {
  ExternalRefsResolved
  ExternalRefsUnchanged
  ExternalRefsRewritten(String)
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
