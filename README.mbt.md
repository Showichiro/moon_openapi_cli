# apispec

Agent-friendly OpenAPI extraction CLI for fetching only the endpoint or schema
context an AI agent needs.

`apispec` reads JSON OpenAPI documents, normalizes OpenAPI 3.0 / 3.1 and
Swagger 2.0 into one internal shape, and emits small structured outputs that
are stable enough for scripts and agents.

## Quick Start

1. Install with Homebrew:

```bash
brew tap Showichiro/tap
brew install apispec
```

Or install a release binary directly:

```bash
curl -fsSL https://raw.githubusercontent.com/Showichiro/moon_openapi_cli/main/scripts/install.sh \
  | sh -s -- --version v0.1.4 --install-dir "$HOME/.local/bin"
```

2. List operations:

```bash
apispec endpoint ls -f openapi.json --quiet
```

3. Extract one operation:

```bash
apispec endpoint get addPet -f openapi.json --format md
```

4. Ask the CLI what agents can call:

```bash
apispec describe --subcommand endpoint.get
```

## Installer Contract

The installer is non-interactive and idempotent. If the requested version is
already installed at the target path, it exits successfully without replacing
the binary.

## Commands

| Command | Purpose |
| --- | --- |
| `apispec endpoint ls` | List OpenAPI operations. |
| `apispec endpoint get <target>` | Extract one operation by operationId, `METHOD PATH`, or path. |
| `apispec endpoint search <query>` | Search operations by operationId, path, summary, method, or tag. |
| `apispec schema ls` | List component schemas. |
| `apispec schema get <name>` | Extract one schema and optionally its usages. |
| `apispec schema search <query>` | Search schemas by name, title, type, description, or property. |
| `apispec describe` | Emit command descriptors with `inputSchema` and `outputSchema`. |
| `apispec version` | Print the CLI version. |

The command grammar follows noun-verb form so agents can explore it
predictably.

## Input

Use `-f <path>` for a JSON file, `-f <http(s) URL>` for a remote JSON
document, or `-f -` for stdin. Omitting `-f` reads stdin.

```bash
yq -o=json openapi.yaml | apispec endpoint ls -f - --quiet
apispec endpoint ls -f https://example.com/openapi.json --quiet
```

YAML is intentionally outside the CLI core. Convert YAML to JSON before passing
it to `apispec`.

## External `$ref`

`endpoint get` and `schema get` include reachable components in the emitted
subset. Internal `$ref` values stay as `$ref` references, and the referenced
definitions are copied under `components` so the subset remains self-contained.

External JSON `$ref` values from local files and `http(s)` URLs are imported
when they point at reachable components. Relative refs are resolved against the
input document location:

```json
{"$ref":"schemas/photo.json#/components/schemas/Photo"}
```

When the referenced external component is found, `apispec` copies it into the
emitted subset and rewrites the reference to an internal `$ref`. `endpoint get
--no-resolve` skips reachable component inclusion and external ref import.

External refs from stdin require absolute `http(s)` URLs because stdin has no
base path. Failed loads, parse errors, missing pointers, and component name
conflicts are reported as warnings.

## Output Contract

`stdout` is reserved for command results. `stderr` is reserved for warnings and
errors.

| Mode | Shape |
| --- | --- |
| `--format json` on `ls` | JSON Lines, one object per line. |
| `--format json` on `get` | Pretty JSON object. |
| `--format md` | Markdown optimized for agent reading. |
| `--quiet` / `-q` | One value per line for composition. `endpoint search --quiet` emits `METHOD PATH` targets for `endpoint get`. |
| `--warnings text` on `get` | Human-readable warnings on stderr. |
| `--warnings json` on `get` | Warning JSON Lines on stderr. |
| `--warnings none` on `get` | Suppress warnings. |
| `--verbose` | Phase timing JSON Lines on stderr. |

Examples:

```bash
apispec endpoint ls -f openapi.json --tag pets --quiet
apispec endpoint search "add pet" -f openapi.json --limit 5 --format json
apispec endpoint ls -f https://example.com/openapi.json --quiet
apispec schema search "category name" -f openapi.json --quiet
apispec schema get Pet -f openapi.json --with-usages --format json --warnings json
```

## Exit Codes

| Code | Meaning | Example |
| --- | --- | --- |
| `0` | Success | Extraction completed. |
| `2` | Usage error | Unsupported `--format`. |
| `3` | Resource not found | Missing operationId or schema. |
| `4` | Parse or unsupported spec error | Broken JSON or unknown OpenAPI version. |
| `5` | Ambiguous match | Path matched multiple methods. |

Errors in non-interactive use are single-line JSON:

```json
{"error":"usage_error","message":"unsupported format: yaml","input":"yaml","suggestion":"supported formats: json, md"}
```

Warnings can also be emitted as JSON Lines:

```bash
apispec endpoint get addPet -f openapi.json --warnings json
```

```json
{"level":"warning","code":"unsupported_external_ref","message":"unsupported external $ref: external.json#/components/schemas/Photo","ref":"external.json#/components/schemas/Photo"}
```

External `$ref` resolution can also emit structured warning codes such as
`external_ref_load_failed`, `external_ref_parse_failed`,
`external_ref_pointer_not_found`, and `external_ref_conflict`.

Verbose mode emits phase timings as JSON Lines on stderr:

```bash
apispec endpoint get addPet -f openapi.json --verbose
```

```json
{"level":"debug","phase":"load","durationMs":2}
{"level":"debug","phase":"extract","durationMs":4}
{"level":"debug","phase":"format","durationMs":1}
{"level":"debug","phase":"total","durationMs":7}
```

## Agent Workflow

For endpoint lookup:

```bash
apispec endpoint search "add pet" -f openapi.json --quiet
apispec endpoint ls -f openapi.json --quiet
apispec endpoint get "POST /pets" -f openapi.json --format md --warnings json
apispec endpoint get addPet -f https://example.com/openapi.json --format md --warnings json
```

For schema impact lookup:

```bash
apispec schema search "pet id" -f openapi.json --quiet
apispec schema get Pet -f openapi.json --with-usages --format json --warnings json
```

For command discovery:

```bash
apispec describe
apispec describe --subcommand schema.get
```

## Related

- [Agent skill](skills/apispec-lookup/SKILL.md) - Focused workflow for AI
  agents using `apispec`.
- [Contributing](CONTRIBUTING.md) - Local build, test, and release workflow.
