#!/usr/bin/env bash
# Install worktrunk (wt) — the git worktree manager for parallel AI agent workflows.
set -euo pipefail

REQUIRED_GIT_MAJOR=2
REQUIRED_GIT_MINOR=43

# 1. Ensure Git >= 2.43.0 (worktrunk requirement)
ensure_git_version() {
  local version major minor
  version="$(git --version | sed 's/git version //')"
  major="$(echo "$version" | cut -d. -f1)"
  minor="$(echo "$version" | cut -d. -f2)"

  if [ "$major" -gt "$REQUIRED_GIT_MAJOR" ] || \
     { [ "$major" -eq "$REQUIRED_GIT_MAJOR" ] && [ "$minor" -ge "$REQUIRED_GIT_MINOR" ]; }; then
    echo "[install-worktrunk] Git $version meets the >= 2.43.0 requirement."
    return
  fi

  # Git is too old — try to upgrade if we have root access
  if [ "$(id -u)" -ne 0 ]; then
    echo "[install-worktrunk] WARNING: Git $version is too old (need >= 2.43.0) but no root access to upgrade." >&2
    echo "[install-worktrunk] WARNING: Continuing anyway — wt may fail at runtime." >&2
    echo "[install-worktrunk] Fix: upgrade git manually (sudo apt-get install git or build from source)" >&2
    return
  fi

  echo "[install-worktrunk] Git $version is too old (need >= 2.43.0). Upgrading from source..."

  local build_dir="/tmp/git-upgrade"
  local git_tag="v2.47.0"
  local git_url="https://github.com/git/git/archive/refs/tags/${git_tag}.tar.gz"

  apt-get update -qq
  apt-get install -y -qq \
    libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev make gcc autoconf

  rm -rf "$build_dir"
  mkdir -p "$build_dir"
  curl -sL "$git_url" | tar -xz -C "$build_dir" --strip-components=1

  make -C "$build_dir" prefix=/usr/local -j"$(nproc)" all
  make -C "$build_dir" prefix=/usr/local install
  rm -rf "$build_dir"

  hash -r
  echo "[install-worktrunk] Git upgraded to $(git --version)."
}

ensure_git_version

# 2. Install Rust/Cargo if missing
if ! command -v cargo &>/dev/null; then
  echo "[install-worktrunk] Installing Rust toolchain via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
else
  echo "[install-worktrunk] Cargo already installed."
fi

# 3. Install worktrunk if missing
if ! command -v wt &>/dev/null; then
  echo "[install-worktrunk] Installing worktrunk..."
  cargo install worktrunk
else
  echo "[install-worktrunk] wt already installed: $(wt --version)"
fi

# 4. Shell integration (one-time) — lets `wt switch` auto-cd in the user's shell
if command -v wt &>/dev/null && ! grep -q 'worktrunk' ~/.zshrc 2>/dev/null; then
  echo "[install-worktrunk] Installing zsh shell integration..."
  wt config shell install zsh --yes
fi

# 5. Final verification — wt must actually run
if wt --version &>/dev/null; then
  echo "[install-worktrunk] Done. wt $(wt --version) at $(which wt)"
else
  echo "[install-worktrunk] FAILED: wt is installed but cannot run." >&2
  echo "[install-worktrunk] This usually means git is too old (need >= 2.43.0, have $(git --version))." >&2
  echo "[install-worktrunk] Fix: upgrade git manually — sudo apt-get install git or build from source." >&2
  exit 1
fi
