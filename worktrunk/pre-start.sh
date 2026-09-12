#!/usr/bin/env bash
#
# worktrunk pre-start hook — seeds a freshly-created worktree with the files git does NOT
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
RESPECT_GITIGNORE=NONE

# Never copied, never shared (repo-root-relative, no trailing slash).
SKIP=(NONE)

# Shared from the primary instead of copied. Each entry is "path:mode":
#   ro   = read-only bind mount   (needs mount privileges; aborts if it can't be made)
#   rw   = read-write bind mount
#   link = plain symlink          (read-write; no privileges needed)
SHARE=(NONE)
# AIDEV-NOTE: bind mounts (ro/rw) need mount privileges — use in containers only; use link on host.
if [ "${DEV_ENV:-}" = "host" ]; then
  # e.g. DEV_ENV=host:      SHARE=( "results:link" "output:link" )
  SHARE=(NONE)
elif [ "${DEV_ENV:-}" = "container" ]; then
  # e.g. DEV_ENV=container: SHARE=( "results:ro" "output:rw" )
  SHARE=(NONE)
elif [ -n "${DEV_ENV:-}" ]; then
  echo "[pre-start] ABORT: DEV_ENV='$DEV_ENV' — must be 'host' or 'container'." >&2
  exit 1
fi

# Abort if any single entry about to be COPIED exceeds this many MB (0 disables the guard).
MAX_COPY_MB=500
# ----------------------------------------------------------------------

SRC="${1:-$(git rev-parse --show-toplevel)}"
DST="$(pwd)"
echo "[pre-start] seeding $DST from $SRC"

# AIDEV-NOTE: On ANY failure, clean up the partially-seeded worktree.
# wt creates the git worktree BEFORE running pre-start, so a failed hook
# leaves an ill-formed worktree behind. This trap prevents that.
cleanup_on_failure() {
  local exit_code=$?
  if [ "$exit_code" -ne 0 ]; then
    echo "[pre-start] CLEANUP: seeding failed (exit $exit_code), removing worktree at $DST" >&2
    # Unmount any bind mounts we may have created
    mount | awk -v d="$DST/" '$3 ~ ("^"d){print $3}' | sort -r | while IFS= read -r m; do
      umount "$m" 2>/dev/null || umount -l "$m" 2>/dev/null || true
    done
    # Remove the worktree directory and prune git's record of it
    rm -rf "$DST"
    git -C "$SRC" worktree prune 2>/dev/null || true
    echo "[pre-start] CLEANUP: worktree removed" >&2
  fi
}
trap cleanup_on_failure EXIT

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
    echo "[pre-start] SHARE: '$path' missing in source, skipping"
    continue
  fi
  [ -e "$DST/$path" ] && continue

  mkdir -p "$DST/$(dirname "$path")"
  case "$mode" in
    link)
      ln -s "$SRC/$path" "$DST/$path"
      echo "[pre-start] symlinked $path"
      ;;
    ro|rw)
      mkdir -p "$DST/$path"
      # AIDEV-NOTE: --rbind, NOT --bind. A plain bind is non-recursive: when the source has
      # submounts (here /app/results/* are bind mounts from the host) the copy shows the bare
      # directories *underneath* them and the data is invisible — silently, with `mount` and a
      # read-only check both looking correct. Verify content, not just the mount.
      if ! mount --rbind "$SRC/$path" "$DST/$path" 2>/dev/null; then
        echo "[pre-start] ABORT: cannot bind-mount '$path' ($mode) — need mount privileges (sudo), or use ':link'." >&2
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
            echo "[pre-start] ABORT: cannot remount '$mnt' read-only." >&2
            umount -R "$DST/$path" 2>/dev/null || true
            exit 1
          fi
        done < <(awk -v d="$DST/$path" '$5 == d || index($5, d "/") == 1 {print $5}' \
                   /proc/self/mountinfo | sort -r)
      fi
      echo "[pre-start] bind-mounted ($mode) $path"
      ;;
    *)
      echo "[pre-start] ABORT: unknown SHARE mode '$mode' for '$path'." >&2
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
      echo "[pre-start] ABORT: '$rel' is ${size_mb}MB > MAX_COPY_MB=$MAX_COPY_MB — add it to SKIP or SHARE." >&2
      exit 1
    fi
  fi

  mkdir -p "$DST/$(dirname "$rel")"
  cp -a "$SRC/$rel" "$DST/$rel"
  echo "[pre-start] copied $rel"
done

echo "[pre-start] done"
