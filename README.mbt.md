# apispec

Agent-friendly OpenAPI extraction CLI for fetching only the endpoint or schema
context an AI agent needs.

`apispec` reads JSON OpenAPI documents, normalizes OpenAPI 3.0 / 3.1 and
Swagger 2.0 into one internal shape, and emits small structured outputs that
are stable enough for scripts and agents.

## Quick Start

1. Install a release binary:

```bash
curl -fsSL https://raw.githubusercontent.com/Showichiro/moon_openapi_cli/main/scripts/install.sh \
  | sh -s -- --version v0.1.0 --install-dir "$HOME/.local/bin"
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
| `apispec schema ls` | List component schemas. |
| `apispec schema get <name>` | Extract one schema and optionally its usages. |
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

## Output Contract

`stdout` is reserved for command results. `stderr` is reserved for warnings and
errors.

| Mode | Shape |
| --- | --- |
| `--format json` on `ls` | JSON Lines, one object per line. |
| `--format json` on `get` | Pretty JSON object. |
| `--format md` | Markdown optimized for agent reading. |
| `--quiet` / `-q` | One value per line for composition. |
| `--warnings text` on `get` | Human-readable warnings on stderr. |
| `--warnings json` on `get` | Warning JSON Lines on stderr. |
| `--warnings none` on `get` | Suppress warnings. |
| `--verbose` | Phase timing JSON Lines on stderr. |

Examples:

```bash
apispec endpoint ls -f openapi.json --tag pets --quiet
apispec endpoint ls -f https://example.com/openapi.json --quiet
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
apispec endpoint ls -f openapi.json --quiet
apispec endpoint get addPet -f openapi.json --format md --warnings json
apispec endpoint get addPet -f https://example.com/openapi.json --format md --warnings json
```

For schema impact lookup:

```bash
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
