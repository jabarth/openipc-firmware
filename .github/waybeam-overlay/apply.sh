#!/usr/bin/env bash
# .github/waybeam-overlay/apply.sh
#
# Applies the Waybeam custom delta on top of a freshly checked-out
# OpenIPC/firmware tree. Designed so the fork always tracks upstream:
#   1. Copy the pure-addition files (waybeam_venc, rtl88x2cu, our CI, docs).
#   2. Re-apply small surgical patches against upstream-maintained shared
#      files (Config.in registration, Makefile 10MB rootfs, defconfig,
#      README). Patches use `git apply --3way` so drift re-adjudicates
#      cleanly; a real conflict fails LOUDLY here, surfacing upstream
#      churn as a red CI run instead of a silently-broken image.
#
# Usage:  apply.sh <repo-root>
# Expects the caller to have already produced a clean upstream checkout +
# committed it (`git add -A && git commit`) so --3way has an index to
# build on. Idempotent: re-running over an already-overlaid tree is a
# no-op for copies, and patches refuse to apply twice.
set -euo pipefail

ROOT="${1:?usage: apply.sh <repo-root>}"
OVERLAY="$(cd "$(dirname "$0")" && pwd)"
FILES="$OVERLAY/files"
PATCHES="$OVERLAY/patches"

cd "$ROOT"

# --- 1. pure additions: copy our files over the upstream tree --------------
while IFS= read -r rel; do
  # rel is relative to "$FILES", POSIX slashes
  dst="$ROOT/${rel//\\//}"
  mkdir -p "$(dirname "$dst")"
  cp -f "$FILES/$rel" "$dst"
done < <(cd "$FILES" && find . -type f -printf '%P\n')

# --- 2. surgical patches against upstream-maintained shared files ---------
shopt -s nullglob
for p in "$PATCHES"/*.patch; do
  echo "::group::waybeam patch $(basename "$p")"
  if git apply --check "$p" 2>/dev/null; then
    git apply --whitespace=nowarn "$p"
    echo "applied (clean)"
  else
    # Already applied? `git apply --reverse --check` detects idempotent
    # re-runs over an overlaid tree and we skip silently. Otherwise retry
    # with --3way so a drifted context lands as a marked conflict blob
    # instead of a hard abort the user can't triage from the log.
    if git apply --reverse --check "$p" 2>/dev/null; then
      echo "already applied; skip"
    elif git apply --3way --whitespace=nowarn "$p"; then
      echo "applied (3-way reconciled)"
    else
      echo "::error::patch FAILED to apply: $(basename "$p")"
      echo "::error::upstream refactored the surrounding context of this"
      echo "::error::file; refresh the patch against the new upstream HEAD."
      exit 1
    fi
  fi
  echo "::endgroup::"
done

# --- 3. sanity: the package tree we just dropped in must be registered ----
test -f "$ROOT/general/package/rtl88x2cu/Config.in" \
  || { echo "::error::rtl88x2cu package missing"; exit 1; }
test -f "$ROOT/general/package/waybeam_venc/Config.in" \
  || { echo "::error::waybeam_venc package missing"; exit 1; }
grep -q 'package/rtl88x2cu/Config.in' "$ROOT/general/package/Config.in" \
  || { echo "::error::rtl88x2cu not sourced in Config.in (patch drift)"; exit 1; }
grep -q 'package/waybeam_venc/Config.in' "$ROOT/general/package/Config.in" \
  || { echo "::error::waybeam_venc not sourced in Config.in (patch drift)"; exit 1; }

echo "== waybeam overlay applied =="
