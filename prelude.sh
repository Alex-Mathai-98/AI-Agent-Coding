#!/usr/bin/env bash
# AIDEV-NOTE: portable prelude — MUST be SOURCED (not `bash`-run) so it sets env in *your* shell.

# Robust by design: conda is guarded so the SAME file works with or without conda (host vs
# container), and REPO_ROOT is derived from this file's own path, so no project path is hardcoded.

# --- Optional conda activation — runs only if BOTH are set/present (safe no-op otherwise) ---
# Fill these in for your machine. Leaving CONDA_ENV empty skips conda entirely; the `-f` guard
# also skips it wherever that conda install is absent (e.g. inside containers).
CONDA_SH="<path-to-conda>"    # e.g. "$HOME/miniconda3/etc/profile.d/conda.sh"
CONDA_ENV="<environment name>"   # e.g. "myenv"; empty = skip conda
if [ -n "$CONDA_ENV" ] && [ -f "$CONDA_SH" ]; then
  source "$CONDA_SH" && conda activate "$CONDA_ENV"
fi

# --- Repo root = parent of this .claude/ dir. Portable across bash + zsh, any cwd, no abs path. ---
# zsh has no BASH_SOURCE; it falls back to the %x prompt escape (the file being sourced).
_src="${BASH_SOURCE[0]:-${(%):-%x}}"
REPO_ROOT="$(cd "$(dirname "$_src")/.." && pwd)"; unset _src

# --- Auto-export project env from dev.env + PYTHONPATH (set -a exports everything in between) ---
# Some projects want "$REPO_ROOT/src" instead of "$REPO_ROOT" on PYTHONPATH — adjust to taste.
set -a
[ -f "$REPO_ROOT/dev.env" ] && source "$REPO_ROOT/dev.env"
export PYTHONPATH="$REPO_ROOT:${PYTHONPATH}"
set +a
