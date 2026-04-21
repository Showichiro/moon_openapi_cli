---
name: apispec-lookup
description: Use apispec to inspect OpenAPI or Swagger JSON documents for API interface questions, endpoint request/response details, schema structure, or schema usage impact. Trigger when a user asks what an API endpoint accepts/returns, where a schema is used, or how to get a minimal OpenAPI subset for an agent.
---

# apispec Lookup

Use `apispec` when the task needs targeted OpenAPI context without reading the
whole spec into the conversation.

## Core Workflow

1. Find candidate operations:

```bash
apispec endpoint ls -f openapi.json --quiet
```

Use `--tag <tag>` or `--method <method>` to narrow the list.

2. Extract one endpoint:

```bash
apispec endpoint get addPet -f openapi.json --format md
```

Prefer `--format md` when explaining an endpoint to a person. Prefer
`--format json` when another tool or script will consume the result.

3. Inspect a schema:

```bash
apispec schema get Pet -f openapi.json --with-usages --format json
```

Use `--with-usages` for impact analysis because it returns operations that
transitively reference the schema.

## Input Rules

- JSON input only.
- Use `-f <path>` for a file.
- Use `-f <http(s) URL>` for a remote JSON OpenAPI or Swagger document.
- Use `-f -` for stdin.
- Reachable external JSON `$ref` values are resolved by `endpoint get` and
  `schema get` for file and `http(s)` inputs. For stdin, use absolute
  `http(s)` refs because relative refs have no base location.
- Convert YAML before calling `apispec`:

```bash
yq -o=json openapi.yaml | apispec endpoint ls -f - --quiet
apispec endpoint ls -f https://example.com/openapi.json --quiet
```

## Recovery

If a lookup fails:

- For `resource_not_found`, run the relevant list command:

```bash
apispec endpoint ls -f openapi.json --quiet
apispec schema ls -f openapi.json --quiet
```

- For `ambiguous_match`, retry with `METHOD PATH` or an operationId:

```bash
apispec endpoint get "GET /pets/{id}" -f openapi.json --format md
```

- For unsupported formats, use `json` or `md`.
- For available command metadata, ask the CLI directly:

```bash
apispec describe
apispec describe --subcommand endpoint.get
```

## Output Contract

- Read successful command results from stdout.
- Read warnings and errors from stderr.
- Prefer `--warnings json` on `get` commands when you need to inspect warnings
  programmatically.
- If external refs fail, inspect warning codes such as
  `external_ref_load_failed`, `external_ref_parse_failed`,
  `external_ref_pointer_not_found`, or `external_ref_conflict`.
- Use `--verbose` when remote specs are slow or you need phase timings on
  stderr.
- Non-interactive errors are one-line JSON with `error`, `message`, and often
  `input` and `suggestion`.
- `ls --format json` emits JSON Lines.
- `--quiet` emits one value per line and is best for composition.
