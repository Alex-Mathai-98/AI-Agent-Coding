#!/usr/bin/env bash
# AIDEV-NOTE: PreToolUse hook — fires before git commit to ensure every
# AGENTS.md in the repo has a corresponding CLAUDE.md with '@AGENTS.md'.
# Claude Code reads CLAUDE.md files, not AGENTS.md — the @-import bridges the gap.

set -euo pipefail

INPUT=$(cat)

# Extract the bash command from the tool input JSON
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$COMMAND" ] && exit 0

# Only trigger on commands that contain git commit
echo "$COMMAND" | grep -qE 'git\s+commit' || exit 0

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0

FOUND_ISSUES=false
REASON_LINES=""

MISSING_CLAUDE=()
INCOMPLETE_CLAUDE=()

# Scan every AGENTS.md in the repo
while IFS= read -r agents_file; do
    dir=$(dirname "$agents_file")

    claude_file="$dir/CLAUDE.md"
    if [ ! -f "$claude_file" ]; then
        # Make path relative for display
        rel_dir="${dir#"$REPO_ROOT"/}"
        MISSING_CLAUDE+=("$rel_dir")
    elif ! grep -qF '@AGENTS.md' "$claude_file"; then
        rel_dir="${dir#"$REPO_ROOT"/}"
        INCOMPLETE_CLAUDE+=("$rel_dir")
    fi
done < <(find "$REPO_ROOT" -name "AGENTS.md" -not -path "*/.git/*" 2>/dev/null)

# ============================================================
# CHECK 1: Missing CLAUDE.md next to AGENTS.md
# ============================================================
if [ ${#MISSING_CLAUDE[@]} -gt 0 ]; then
    FOUND_ISSUES=true
    REASON_LINES+="[Missing CLAUDE.md for AGENTS.md] Create a CLAUDE.md containing '@AGENTS.md' in each directory below:\\n"
    echo "================================================================" >&2
    echo "CHECK: MISSING CLAUDE.md FOR AGENTS.md" >&2
    echo "" >&2
    echo "The following directories have AGENTS.md but NO CLAUDE.md." >&2
    echo "Claude Code won't read AGENTS.md unless a CLAUDE.md with" >&2
    echo "'@AGENTS.md' exists in the same directory:" >&2
    echo "" >&2
    for entry in "${MISSING_CLAUDE[@]}"; do
        REASON_LINES+="  - $entry/CLAUDE.md missing (create with content '@AGENTS.md')\\n"
        echo "  * $entry/" >&2
    done
    echo "" >&2
    echo "FIX: Create a CLAUDE.md in each directory above containing:" >&2
    echo "  @AGENTS.md" >&2
    echo "" >&2
fi

# ============================================================
# CHECK 2: CLAUDE.md exists but doesn't import @AGENTS.md
# ============================================================
if [ ${#INCOMPLETE_CLAUDE[@]} -gt 0 ]; then
    FOUND_ISSUES=true
    REASON_LINES+="[CLAUDE.md missing @AGENTS.md import] Add '@AGENTS.md' to CLAUDE.md in each directory below:\\n"
    echo "================================================================" >&2
    echo "CHECK: CLAUDE.md MISSING @AGENTS.md IMPORT" >&2
    echo "" >&2
    echo "The following directories have both AGENTS.md and CLAUDE.md," >&2
    echo "but the CLAUDE.md does NOT contain '@AGENTS.md':" >&2
    echo "" >&2
    for entry in "${INCOMPLETE_CLAUDE[@]}"; do
        REASON_LINES+="  - $entry/CLAUDE.md needs '@AGENTS.md' added\\n"
        echo "  * $entry/" >&2
    done
    echo "" >&2
    echo "FIX: Add '@AGENTS.md' to the CLAUDE.md in each directory above." >&2
    echo "" >&2
fi

# If no issues found, allow the commit
$FOUND_ISSUES || exit 0

# ============================================================
# Summary
# ============================================================
echo "================================================================" >&2
echo "ACTION: Create or update CLAUDE.md files so Claude Code can read" >&2
echo "the AGENTS.md content, or approve to commit as-is." >&2
echo "================================================================" >&2

cat <<EOF
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": "${REASON_LINES}Approve to commit as-is, or deny to fix first."}}
EOF
exit 0
