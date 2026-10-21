#!/usr/bin/env bash
set -euo pipefail

version="$(rtk --version | awk '{print $2}')"
binary_dir="$(dirname "$(command -v rtk)")"
if [[ -x "$binary_dir/rtk-proxy" ]] &&
   [[ "$("$binary_dir/rtk-proxy" --version 2>/dev/null)" == "rtk-proxy $version" ]]; then
  echo "RTK proxy ${version} already installed."
  exit 0
fi

case "$(uname -m)" in
  arm64) target=aarch64-apple-darwin ;;
  x86_64) target=x86_64-apple-darwin ;;
  *) echo "ERROR: Unsupported RTK proxy architecture: $(uname -m)" >&2; exit 1 ;;
esac

archive="rtk-proxy-${target}.tar.gz"
release="https://github.com/rtk-ai/rtk/releases/download/v${version}"
temporary_dir="$(mktemp -d)"
trap 'rm -rf "$temporary_dir"' EXIT

echo "Installing RTK proxy ${version}..."
curl -fsSL "$release/$archive" -o "$temporary_dir/$archive"
curl -fsSL "$release/checksums.txt" -o "$temporary_dir/checksums.txt"
(
  cd "$temporary_dir"
  awk -v archive="$archive" '$2 == archive { print }' checksums.txt | shasum -a 256 -c -
  tar -xzf "$archive" rtk-proxy
)
install -m 755 "$temporary_dir/rtk-proxy" "$binary_dir/rtk-proxy"
rtk llm-proxy setup
