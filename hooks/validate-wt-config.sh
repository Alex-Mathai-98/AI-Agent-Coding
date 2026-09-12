#!/usr/bin/env bash
#
# Validate worktrunk (wt) configuration before any worktree operations.
# Catches misconfigurations early — each one cost hours of debugging.
#
# Usage: bash .claude/hooks/validate-wt-config.sh
# Exit 0 = all checks pass. Exit 1 = at least one failure.

set -uo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo /app)"
cd "$REPO_ROOT"

FAILURES=()

fail() {
  FAILURES+=("  [$1] $2")
}

# ── Check 1: wt installed ──
if ! command -v wt &>/dev/null; then
  # Check common cargo location before failing
  if [ -x "$HOME/.cargo/bin/wt" ]; then
    fail 1 "wt is at $HOME/.cargo/bin/wt but not in PATH. Fix: export PATH=\$PATH:\$HOME/.cargo/bin"
  else
    fail 1 "wt (worktrunk) not installed. Fix: cargo install worktrunk"
  fi
fi

# ── Check 2: .claude/.config must NOT exist ──
if [ -d ".claude/.config" ]; then
  fail 2 "Stale .claude/.config/ exists — delete it. wt reads from .config/wt.toml, not .claude/.config/. Fix: rm -rf .claude/.config"
fi

# ── Check 3: .config/wt.toml must exist ──
if [ ! -f ".config/wt.toml" ]; then
  fail 3 ".config/wt.toml missing — this is the default project config wt reads. Fix: wt config create --project"
fi

# ── Check 4: WORKTRUNK_PROJECT_CONFIG_PATH must be unset ──
if [ -n "${WORKTRUNK_PROJECT_CONFIG_PATH:-}" ]; then
  fail 4 "WORKTRUNK_PROJECT_CONFIG_PATH is set to '$WORKTRUNK_PROJECT_CONFIG_PATH' — this overrides the default .config/wt.toml. Fix: unset WORKTRUNK_PROJECT_CONFIG_PATH (and remove from /etc/environment if present)"
fi

# ── Check 4b: DEV_ENV must be set to 'host' or 'container' ──
if [ -z "${DEV_ENV:-}" ]; then
  fail 4b "DEV_ENV is not set — source dev.env or docker.env first. Fix: add DEV_ENV=host (or container) to your env file"
elif [ "$DEV_ENV" != "host" ] && [ "$DEV_ENV" != "container" ]; then
  fail 4b "DEV_ENV is '$DEV_ENV' — must be 'host' or 'container'. Fix: set DEV_ENV=host or DEV_ENV=container in your env file"
fi

# ── Check 5: PATH contains .cargo ──
if ! echo "$PATH" | grep -q '\.cargo'; then
  fail 5 "PATH does not contain .cargo/bin — wt and other Rust tools won't be found. Fix: export PATH=\$PATH:\$HOME/.cargo/bin"
fi

# ── Check 6: pre-start.sh exists and is executable ──
if [ ! -f ".claude/worktrunk/pre-start.sh" ]; then
  fail 6 "pre-start.sh not found at .claude/worktrunk/pre-start.sh"
elif [ ! -x ".claude/worktrunk/pre-start.sh" ]; then
  fail 6 "pre-start.sh exists but is not executable. Fix: chmod +x .claude/worktrunk/pre-start.sh"
fi

# ── Check 7: pre-remove.sh exists and is executable ──
if [ ! -f ".claude/worktrunk/pre-remove.sh" ]; then
  fail 7 "pre-remove.sh not found at .claude/worktrunk/pre-remove.sh"
elif [ ! -x ".claude/worktrunk/pre-remove.sh" ]; then
  fail 7 "pre-remove.sh exists but is not executable. Fix: chmod +x .claude/worktrunk/pre-remove.sh"
fi

# ── Checks 9a-9d: pre-start.sh configuration values ──
if [ -f ".claude/worktrunk/pre-start.sh" ]; then
  HOOK=".claude/worktrunk/pre-start.sh"

  # 9a: RESPECT_GITIGNORE must not be NONE
  if grep -qE '^RESPECT_GITIGNORE=NONE' "$HOOK"; then
    fail 9a "RESPECT_GITIGNORE in pre-start.sh is still NONE — set it to 'true' or 'false'"
  fi

  # 9b: SKIP must not be (NONE)
  if grep -qE '^SKIP=\(NONE\)' "$HOOK"; then
    fail 9b "SKIP in pre-start.sh is still (NONE) — set it to a list of directories or empty ()"
  fi

  # 9c: SHARE must not be (NONE)
  if grep -qE '^SHARE=\(.*NONE.*\)' "$HOOK"; then
    fail 9c "SHARE in pre-start.sh is still (NONE) — set it to a list of entries or empty ()"
  fi

  # 9d: No commas in SKIP or SHARE arrays
  if grep -qE '^SKIP=\(.*,.*\)' "$HOOK"; then
    fail 9d "Comma found in SKIP array — bash arrays use spaces, not commas. Fix: SKIP=(a b c) not SKIP=(a, b, c)"
  fi
  if grep -qE '^SHARE=\(.*,[^:}].*\)' "$HOOK"; then
    fail 9d "Comma found in SHARE array — bash arrays use spaces, not commas"
  fi
fi

# ── Check 10: .claude/worktrunk/approvals.toml must NOT exist ──
if [ -d ".claude/worktrunk" ] && [ -f ".claude/worktrunk/approvals.toml" ]; then
  fail 10 ".claude/worktrunk/approvals.toml should not exist — wt reads approvals from ~/.config/worktrunk/approvals.toml. Fix: rm .claude/worktrunk/approvals.toml"
fi

# ── Check 11: ~/.config/worktrunk/approvals.toml must exist with real values ──
APPROVALS_FILE="$HOME/.config/worktrunk/approvals.toml"
if [ ! -f "$APPROVALS_FILE" ]; then
  fail 11 "No hook approvals configured — agents cannot create worktrees non-interactively. Fix: wt config approvals add --yes"
else
  if grep -q '<YOUR_PROJECT_IDENTIFIER>' "$APPROVALS_FILE"; then
    fail 11 "$APPROVALS_FILE still has placeholder <YOUR_PROJECT_IDENTIFIER> — run: wt config approvals add --yes"
  fi
  REPO_ID=$(cd "$REPO_ROOT" && command -v wt &>/dev/null && wt config show 2>/dev/null | grep 'Identifier:' | awk '{print $NF}' || true)
  if [ -n "$REPO_ID" ] && ! grep -q "$REPO_ID" "$APPROVALS_FILE" 2>/dev/null; then
    fail 11 "Hook approvals exist but not for this project ($REPO_ID). Fix: wt config approvals add --yes"
  fi
fi

# ── Report ──
if [ ${#FAILURES[@]} -eq 0 ]; then
  echo "[validate-wt-config] All checks passed ✓"
  exit 0
else
  echo "[validate-wt-config] ${#FAILURES[@]} check(s) failed:" >&2
  for f in "${FAILURES[@]}"; do
    echo "$f" >&2
  done
  exit 1
fi
