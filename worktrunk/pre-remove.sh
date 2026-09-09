#!/usr/bin/env bash
# AIDEV-NOTE: worktrunk pre-remove hook. Unmount any bind mounts under this worktree BEFORE
# removal (busy mountpoints block `wt remove`). Runs IN the worktree being removed.
set -euo pipefail
WT="$(pwd)"
mount | awk -v d="$WT/" '$3 ~ ("^"d){print $3}' | sort -r | while IFS= read -r m; do
  umount "$m" 2>/dev/null || umount -l "$m" 2>/dev/null || true
  echo "[pre-remove] unmounted $m"
done
echo "[pre-remove] done"
