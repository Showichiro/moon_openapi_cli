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

## GitHub Actions Maintenance

Workflow actions are pinned to full commit SHAs with a version comment using
`pinact`. Dependabot checks GitHub Actions weekly and opens update PRs when
new versions are available. The Pinact workflow also validates workflow action
pins in `skip_push` mode on PRs and `main` pushes that touch workflow files.

Refresh action pins manually when needed:

```bash
pinact run --update
actionlint .github/workflows/*.yml
```

Verify that all workflow actions are pinned:

```bash
pinact run --check
```

## Release

`main` should stay releasable. Do not bump versions in ordinary feature,
fix, docs, or refactor PRs. Prepare a release in a dedicated release PR, then
tag the merge commit after it lands on `main`.

Use SemVer as follows:

| Version | Use for |
| --- | --- |
| patch | Bug fixes, docs, help text, and behavior-compatible refactors. |
| minor | New commands, flags, output fields, or opt-in behavior. |
| major | Breaking flag semantics or output shape changes. |

Prepare release metadata from a clean worktree:

```bash
git switch main
git pull --ff-only
git switch -c release/vX.Y.Z
scripts/prepare-release.sh vX.Y.Z
git diff
git add cmd/main/main.mbt moon.mod.json README.mbt.md pkg.generated.mbti
git commit -m "release vX.Y.Z"
git push -u origin release/vX.Y.Z
```

Open a PR to `main` named `Release vX.Y.Z`. The release preparation script
updates:

- `cmd/main/main.mbt`
- `moon.mod.json`
- fixed README install examples

It also runs `scripts/verify-version.sh`, `moon info && moon fmt`,
`moon check`, `moon test`, and `git diff --check` unless `--no-validate` is
passed.

After the release PR is merged, tag the merge commit and push the tag:

```bash
git switch main
git pull --ff-only
git tag vX.Y.Z
git push origin vX.Y.Z
```

Treat release tags as immutable. If a release is wrong, publish a new patch
release instead of moving an existing tag.

CI runs `scripts/verify-version.sh` on normal PRs and `main` pushes to catch
partial version bumps. The release workflow runs the same script with the tag
name, then builds native binaries for Linux x64 and macOS arm64 and uploads
assets named:

```text
apispec-vX.Y.Z-linux-x64
apispec-vX.Y.Z-macos-arm64
```

The installer downloads these assets by version and platform.

The Homebrew Formula is maintained by the `Showichiro/homebrew-tap` repository.
Its scheduled/manual workflow reads this repository's latest release and commits
Formula URL/SHA256 updates to the tap using that repository's own
`GITHUB_TOKEN`.

## Related

- [README](README.md) - User-facing install and CLI usage.
- [Agent skill](skills/apispec-lookup/SKILL.md) - Agent workflow for targeted
  OpenAPI lookup.
