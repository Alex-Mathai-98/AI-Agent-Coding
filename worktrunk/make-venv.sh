#!/usr/bin/env bash
# worktrunk pre-start hook: this checkout's own .venv with an editable install of this checkout.
# Also run by hand once in the primary and in worktrees made before this hook.
# VENV_EXTRAS: optional extras to install, e.g. VENV_EXTRAS=dev (set in pre-start.sh CONFIG).
set -euo pipefail
DST="$(pwd)"
if [ ! -f "$DST/pyproject.toml" ] && [ ! -f "$DST/setup.py" ]; then
  echo "[make-venv] no pyproject.toml / setup.py in $DST: no venv"
  exit 0
fi
target="$DST"
[ -n "${VENV_EXTRAS:-}" ] && target="$DST[$VENV_EXTRAS]"
uv venv --quiet --clear "$DST/.venv"
uv pip install --quiet --python "$DST/.venv/bin/python" -e "$target"

# AIDEV-NOTE: every editable install in the venv must point inside this checkout (a copied or
# mis-built venv would silently run another checkout's code).
shopt -s nullglob
pth=( "$DST"/.venv/lib/python*/site-packages/__editable__*.pth )
if [ "${#pth[@]}" -eq 0 ]; then
  echo "[make-venv] ABORT: no editable install in $DST/.venv" >&2
  exit 1
fi
bad="$(grep -hv "^$DST/" "${pth[@]}" | grep -v "^$DST\$" || true)"
if [ -n "$bad" ]; then
  echo "[make-venv] ABORT: .venv points outside $DST: $bad" >&2
  exit 1
fi
echo "[make-venv] .venv ready: editable install of $DST"
