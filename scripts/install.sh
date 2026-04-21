#!/bin/sh
set -eu

repo="${APISPEC_REPO:-Showichiro/moon_openapi_cli}"
version="latest"
install_dir="${HOME}/.local/bin"

usage() {
  cat <<'EOF'
Usage: install.sh [--version vX.Y.Z] [--install-dir DIR] [--repo OWNER/REPO]

Installs the apispec release binary for the current OS and CPU architecture.
The script is non-interactive and idempotent.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --version)
      version="${2:?missing value for --version}"
      shift 2
      ;;
    --install-dir)
      install_dir="${2:?missing value for --install-dir}"
      shift 2
      ;;
    --repo)
      repo="${2:?missing value for --repo}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "install.sh: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux) echo "linux" ;;
    *)
      echo "install.sh: unsupported OS: $(uname -s)" >&2
      exit 4
      ;;
  esac
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "x64" ;;
    arm64|aarch64) echo "arm64" ;;
    *)
      echo "install.sh: unsupported architecture: $(uname -m)" >&2
      exit 4
      ;;
  esac
}

resolve_latest_version() {
  effective_url="$(
    curl -fsSL -o /dev/null -w '%{url_effective}' \
      "https://github.com/${repo}/releases/latest"
  )"
  tag="${effective_url##*/}"
  if [ -z "$tag" ] || [ "$tag" = "latest" ]; then
    echo "install.sh: failed to resolve latest release for ${repo}" >&2
    exit 4
  fi
  echo "$tag"
}

if [ "$version" = "latest" ]; then
  version="$(resolve_latest_version)"
fi

os="$(detect_os)"
arch="$(detect_arch)"
asset="apispec-${version}-${os}-${arch}"
url="https://github.com/${repo}/releases/download/${version}/${asset}"
bin="${install_dir}/apispec"
expected_version="${version#v}"

if [ -x "$bin" ]; then
  current_version="$("$bin" version 2>/dev/null || true)"
  if [ "$current_version" = "$expected_version" ]; then
    echo "apispec ${current_version} already installed at ${bin}" >&2
    exit 0
  fi
fi

tmp="${TMPDIR:-/tmp}/apispec-install.$$"
trap 'rm -f "$tmp"' EXIT HUP INT TERM

mkdir -p "$install_dir"
curl -fsSL "$url" -o "$tmp"
chmod 0755 "$tmp"
mv "$tmp" "$bin"

installed_version="$("$bin" version 2>/dev/null || true)"
if [ "$installed_version" != "$expected_version" ]; then
  echo "install.sh: installed version '${installed_version}' did not match '${expected_version}'" >&2
  exit 4
fi

echo "installed apispec ${installed_version} at ${bin}" >&2
