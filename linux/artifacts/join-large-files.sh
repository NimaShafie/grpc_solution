#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
reassemble() {
  local base="$1"
  if ls "${base}".part* >/dev/null 2>&1; then
    echo "[*] Reassembling ${base} ..."
    cat "${base}".part* > "${base}"
    echo "[OK] Wrote ${base}"
  else
    echo "[skip] No parts for ${base}"
  fi
}
reassemble "offline-bundle-v1.76.0.tar.xz"
reassemble "grpc-v1.76.0-source-with-submodules.tar.xz"
echo "Done."
