# Contributing

This repository is a MoonBit project. Run commands from the repository root.

## Local Setup

Install MoonBit, then confirm the toolchain:

```bash
moon version --all
moon update
```

Build the CLI:

```bash
moon build cmd/main --target native --release --strip
cp _build/native/release/build/cmd/main/main.exe ./apispec
./apispec version
```

## Validation

Run the standard validation before committing:

```bash
moon info && moon fmt
moon check && moon test && moon build
git diff --check
```

For CLI smoke tests:

```bash
moon build cmd/main --target native --release --strip
cp _build/native/release/build/cmd/main/main.exe ./apispec
./apispec describe --subcommand endpoint.get
./apispec endpoint ls -f tests/fixtures/petstore_v3.json --quiet
./apispec endpoint get addPet -f tests/fixtures/petstore_v3.json --format md
```

## Release

Create and push a `v*` tag. The release workflow builds native binaries for
Linux x64, macOS x64, and macOS arm64, then uploads assets named:

```text
apispec-vX.Y.Z-linux-x64
apispec-vX.Y.Z-macos-x64
apispec-vX.Y.Z-macos-arm64
```

The installer downloads these assets by version and platform.

## Related

- [README](README.md) - User-facing install and CLI usage.
- [Agent skill](skills/apispec-lookup/SKILL.md) - Agent workflow for targeted
  OpenAPI lookup.
