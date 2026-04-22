///|
pub struct SearchTerms {
  phrase : String
  tokens : Array[String]
  groups : Array[Array[String]]
}

///|
pub fn build_search_terms(query : String) -> SearchTerms {
  let phrase = normalize_search_text(query)
  let tokens : Array[String] = []
  let groups : Array[Array[String]] = []
  for view in phrase.split(" ") {
    let token = view.to_string()
    if !token.is_empty() {
      let alternatives : Array[String] = []
      add_unique_token(alternatives, token)
      add_query_aliases(alternatives, token)
      for alternative in alternatives {
        add_unique_token(tokens, alternative)
      }
      groups.push(alternatives)
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
pub fn count_matched_groups(values : Array[String], terms : SearchTerms) -> Int {
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
  group : Array[String],
) -> Bool {
  let mut found = false
  for term in group {
    for value in normalized_values {
      if value.contains(term) {
        found = true
      }
    }
  }
  found
}

///|
pub fn coverage_bonus(terms : SearchTerms, matched : Int) -> Int {
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
pub fn score_field(
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
