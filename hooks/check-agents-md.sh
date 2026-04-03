#!/usr/bin/env bash
# AIDEV-NOTE: PreToolUse hook — fires before git commit to:
#   1. Warn about stale AGENTS.md files covering modified directories
#   2. Flag directories with >=5 files but no AGENTS.md anywhere up the tree
# Reads tool input JSON from stdin. Exits 2 to block commit if issues found.

set -euo pipefail

# AIDEV-NOTE: skip hook if user already declined the AGENTS.md update/creation
[ "${SKIP_AGENTS_CHECK:-0}" = "1" ] && exit 0

INPUT=$(cat)

# Extract the bash command from the tool input JSON
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$COMMAND" ] && exit 0

# Only trigger on commands that contain git commit (handles compound commands like "git add && git commit")
echo "$COMMAND" | grep -qE 'git\s+commit' || exit 0

# AIDEV-NOTE: Allow skipping via command prefix (e.g. "SKIP_AGENTS_CHECK=1 git commit ...")
# Since this hook runs as a PreToolUse subprocess, env vars from the bash command
# don't propagate. Instead, parse the command string for the skip flag.
echo "$COMMAND" | grep -qE 'SKIP_AGENTS_CHECK=1' && exit 0

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0

# Prefer staged files; fall back to all modified tracked files
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null)
if [ -z "$STAGED_FILES" ]; then
    STAGED_FILES=$(git diff --name-only 2>/dev/null)
fi
[ -z "$STAGED_FILES" ] && exit 0

# Collect unique directories that contain changed files
declare -A SEEN_DIRS
while IFS= read -r file; do
    dir=$(dirname "$file")
    SEEN_DIRS["$dir"]=1
done <<< "$STAGED_FILES"

FOUND_ISSUES=false

# ============================================================
# CHECK 1: Stale AGENTS.md — exists but not updated
# ============================================================
declare -A AGENTS_MAP  # agents_file -> list of source dirs
for dir in "${!SEEN_DIRS[@]}"; do
    current="$dir"
    while [ "$current" != "." ] && [ "$current" != "/" ]; do
        candidate="$current/AGENTS.md"
        if [ -f "$REPO_ROOT/$candidate" ]; then
            if [ -z "${AGENTS_MAP[$candidate]+x}" ]; then
                AGENTS_MAP["$candidate"]="$dir"
            else
                AGENTS_MAP["$candidate"]="${AGENTS_MAP[$candidate]}, $dir"
            fi
            break
        fi
        current=$(dirname "$current")
    done
done

UNSTAGED_AGENTS=()
for agents_file in "${!AGENTS_MAP[@]}"; do
    if ! echo "$STAGED_FILES" | grep -qxF "$agents_file"; then
        UNSTAGED_AGENTS+=("$agents_file")
    fi
done

if [ ${#UNSTAGED_AGENTS[@]} -gt 0 ]; then
    FOUND_ISSUES=true
    echo "================================================================" >&2
    echo "CHECK 1: AGENTS.md UPDATE CHECK" >&2
    echo "" >&2
    echo "The following AGENTS.md files cover directories with modified code" >&2
    echo "but were NOT updated in this commit:" >&2
    echo "" >&2
    for agents_file in "${UNSTAGED_AGENTS[@]}"; do
        echo "  * $agents_file" >&2
        echo "    (covers changes in: ${AGENTS_MAP[$agents_file]})" >&2
    done
    echo "" >&2
fi

# ============================================================
# CHECK 2: Missing AGENTS.md — directory has >=5 files, no AGENTS.md in its own dir
# AIDEV-NOTE: Per Anthropic best practices, each significant subdirectory should
# have its own AGENTS.md even if a parent has one. Only check the immediate directory.
# ============================================================
MISSING_AGENTS=()
for dir in "${!SEEN_DIRS[@]}"; do
    full_dir="$REPO_ROOT/$dir"
    [ -d "$full_dir" ] || continue

    # Check if this directory itself has an AGENTS.md
    [ -f "$full_dir/AGENTS.md" ] && continue

    # No AGENTS.md in this directory — check file count
    file_count=$(find "$full_dir" -maxdepth 1 -type f | wc -l)
    if [ "$file_count" -ge 5 ]; then
        MISSING_AGENTS+=("$dir (${file_count} files)")
    fi
done

if [ ${#MISSING_AGENTS[@]} -gt 0 ]; then
    FOUND_ISSUES=true
    echo "================================================================" >&2
    echo "CHECK 2: MISSING AGENTS.md CHECK" >&2
    echo "" >&2
    echo "The following directories have 5 or more files but NO AGENTS.md" >&2
    echo "anywhere in their directory tree:" >&2
    echo "" >&2
    for entry in "${MISSING_AGENTS[@]}"; do
        echo "  * $entry" >&2
    done
    echo "" >&2
fi

# If no issues found, allow the commit
$FOUND_ISSUES || exit 0

# ============================================================
# Summary
# ============================================================
echo "================================================================" >&2
echo "Modified files in this commit:" >&2
echo "$STAGED_FILES" | sed 's/^/  - /' >&2
echo "" >&2
echo "ACTION: Ask the user about each finding above before proceeding" >&2
echo "with the commit. For CHECK 1, ask if they want to update the" >&2
echo "AGENTS.md. For CHECK 2, ask if they want to generate a new" >&2
echo "AGENTS.md per CLAUDE.md (Sections 5 & 6)." >&2
echo "================================================================" >&2

# AIDEV-NOTE: exit 2 blocks the git commit via PreToolUse, forcing the LLM to address this first
exit 2
