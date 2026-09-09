#!/usr/bin/env bash
#
# worktrunk post-start hook — seeds a freshly-created worktree with the files git does NOT
# put there: untracked files, plus gitignored ones when RESPECT_GITIGNORE=false.
#
# Runs IN the new worktree (cwd = the new worktree). $1 = the primary worktree (source).
# Behaviour is driven entirely by the CONFIG block below.
# Any bind mounts created here are torn down by pre-remove.sh on `wt remove`.
#
# AIDEV-NOTE: per-entry precedence is SHARE > SKIP > (size-guarded) COPY.

set -euo pipefail

# ------------------------------- CONFIG -------------------------------
# Copy gitignored files too?  false = copy-everything;  true = respect .gitignore.
RESPECT_GITIGNORE=false

# Never copied, never shared (repo-root-relative, no trailing slash).
SKIP=()          # e.g. SKIP=( build dist .venv scratch.md )

# Shared from the primary instead of copied. Each entry is "path:mode":
#   ro   = read-only bind mount   (needs mount privileges; aborts if it can't be made)
#   rw   = read-write bind mount
#   link = plain symlink          (read-write; no privileges needed)
SHARE=()         # e.g. SHARE=( "results:ro" "big-data:link" )

# Abort if any single entry about to be COPIED exceeds this many MB (0 disables the guard).
MAX_COPY_MB=500
# ----------------------------------------------------------------------

SRC="${1:-$(git rev-parse --show-toplevel)}"
DST="$(pwd)"
echo "[post-start] seeding $DST from $SRC"

# Return 0 if the first argument appears among the remaining arguments.
in_list() {
  local needle="$1"; shift
  local item
  for item in "$@"; do
    [ "$item" = "$needle" ] && return 0
  done
  return 1
}

# Path component of each SHARE entry, for the copy-exclusion check below.
# Built before the pipeline so the `while` subshell inherits it.
mapfile -t SHARE_NAMES < <(for entry in "${SHARE[@]}"; do printf '%s\n' "${entry%%:*}"; done)

cd "$SRC"

# --- SHARE: symlink or bind-mount each entry (these are never copied) ---
for entry in "${SHARE[@]}"; do
  path="${entry%%:*}"
  mode="${entry##*:}"
  [ "$path" = "$mode" ] && mode="link"          # bare "results" behaves like "results:link"

  if [ ! -e "$SRC/$path" ]; then
    echo "[post-start] SHARE: '$path' missing in source, skipping"
    continue
  fi
  [ -e "$DST/$path" ] && continue

  mkdir -p "$DST/$(dirname "$path")"
  case "$mode" in
    link)
      ln -s "$SRC/$path" "$DST/$path"
      echo "[post-start] symlinked $path"
      ;;
    ro|rw)
      mkdir -p "$DST/$path"
      # AIDEV-NOTE: --rbind, NOT --bind. A plain bind is non-recursive: when the source has
      # submounts (e.g. a shared dir that is itself a bind mount) the copy shows the bare
      # directories *underneath* them and the data is invisible — silently, with `mount` and a
      # read-only check both looking correct. Verify content, not just the mount.
      if ! mount --rbind "$SRC/$path" "$DST/$path" 2>/dev/null; then
        echo "[post-start] ABORT: cannot bind-mount '$path' ($mode) — need mount privileges (sudo), or use ':link'." >&2
        rmdir "$DST/$path" 2>/dev/null || true
        exit 1
      fi
      # Detach from the source's propagation so unmounting here can never unmount the source.
      mount --make-rslave "$DST/$path" 2>/dev/null || true
      if [ "$mode" = ro ]; then
        # Read-only has to be applied per submount, deepest first: util-linux < 2.38 has no
        # recursive remount, so `remount,ro` on the top leaves every submount writable.
        while read -r mnt; do
          if ! mount -o remount,ro,bind "$mnt" 2>/dev/null; then
            echo "[post-start] ABORT: cannot remount '$mnt' read-only." >&2
            umount -R "$DST/$path" 2>/dev/null || true
            exit 1
          fi
        done < <(awk -v d="$DST/$path" '$5 == d || index($5, d "/") == 1 {print $5}' \
                   /proc/self/mountinfo | sort -r)
      fi
      echo "[post-start] bind-mounted ($mode) $path"
      ;;
    *)
      echo "[post-start] ABORT: unknown SHARE mode '$mode' for '$path'." >&2
      exit 1
      ;;
  esac
done

# --- COPY everything git leaves out (top-level granularity), except SHARE / SKIP ---
# NOTE: `exit 1` inside the while (a pipeline subshell) still aborts the whole script under
# `set -e`, because the pipeline's exit status becomes non-zero.
{
  git ls-files -o --exclude-standard --directory -z
  [ "$RESPECT_GITIGNORE" = false ] && git ls-files -o --ignored --exclude-standard --directory -z
} | while IFS= read -r -d '' entry; do
  rel="${entry%/}"                              # strip trailing slash from directory entries
  in_list "$rel" "${SHARE_NAMES[@]}" && continue
  in_list "$rel" "${SKIP[@]}"        && continue

  if [ "$MAX_COPY_MB" -gt 0 ]; then
    size_mb="$(du -sm "$SRC/$rel" 2>/dev/null | cut -f1)"
    if [ "${size_mb:-0}" -gt "$MAX_COPY_MB" ]; then
      echo "[post-start] ABORT: '$rel' is ${size_mb}MB > MAX_COPY_MB=$MAX_COPY_MB — add it to SKIP or SHARE." >&2
      exit 1
    fi
  fi

  mkdir -p "$DST/$(dirname "$rel")"
  cp -a "$SRC/$rel" "$DST/$rel"
  echo "[post-start] copied $rel"
done

echo "[post-start] done"
