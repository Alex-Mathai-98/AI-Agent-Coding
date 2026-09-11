#!/usr/bin/env bash
# Install worktrunk (wt) — the git worktree manager for parallel AI agent workflows.
set -euo pipefail

# 1. Install Rust/Cargo if missing
if ! command -v cargo &>/dev/null; then
  echo "[install-worktrunk] Installing Rust toolchain via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
else
  echo "[install-worktrunk] Cargo already installed."
fi

# 2. Install worktrunk if missing
if ! command -v wt &>/dev/null; then
  echo "[install-worktrunk] Installing worktrunk..."
  cargo install worktrunk
else
  echo "[install-worktrunk] wt already installed: $(wt --version)"
fi

echo "[install-worktrunk] Done. wt is at: $(which wt)"
