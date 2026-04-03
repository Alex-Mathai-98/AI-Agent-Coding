#!/usr/bin/env bash
# AIDEV-NOTE: PreToolUse hook — fires before git commit to:
#   1. Warn about stale AGENTS.md files covering modified directories
#   2. Flag directories with >=5 files but no AGENTS.md anywhere up the tree
# Outputs permissionDecision: "ask" to delegate approval to the user when issues found.

set -euo pipefail

INPUT=$(cat)

# Extract the bash command from the tool input JSON
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$COMMAND" ] && exit 0

# Only trigger on commands that contain git commit (handles compound commands like "git add && git commit")
echo "$COMMAND" | grep -qE 'git\s+commit' || exit 0


REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0

# AIDEV-NOTE: Only check staged files. If nothing is staged, git commit will
# fail on its own — no need for the hook to fall back to unstaged files.
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null)
[ -z "$STAGED_FILES" ] && exit 0

# Collect unique directories that contain changed files
declare -A SEEN_DIRS
while IFS= read -r file; do
    dir=$(dirname "$file")
    SEEN_DIRS["$dir"]=1
done <<< "$STAGED_FILES"

FOUND_ISSUES=false
REASON_LINES=""

# ============================================================
# CHECK 1: Stale AGENTS.md — exists but not updated
# ============================================================
# AIDEV-NOTE: Two maps — AGENTS_MAP groups dirs by AGENTS.md file,
# FILE_TO_AGENTS maps each staged file to its covering AGENTS.md.
declare -A AGENTS_MAP  # agents_file -> list of source dirs
declare -A FILE_TO_AGENTS  # staged_file -> covering agents_file
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
            # Map each staged file in this dir to its AGENTS.md
            while IFS= read -r staged_file; do
                file_dir=$(dirname "$staged_file")
                if [ "$file_dir" = "$dir" ]; then
                    FILE_TO_AGENTS["$staged_file"]="$candidate"
                fi
            done <<< "$STAGED_FILES"
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
    REASON_LINES+="[Stale AGENTS.md]\\n"
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
    # Build reason with file -> AGENTS.md causation
    for staged_file in "${!FILE_TO_AGENTS[@]}"; do
        covering="${FILE_TO_AGENTS[$staged_file]}"
        # Only include if the covering AGENTS.md is in the unstaged list
        for unstaged in "${UNSTAGED_AGENTS[@]}"; do
            if [ "$covering" = "$unstaged" ]; then
                REASON_LINES+="  $staged_file -> $covering\\n"
                break
            fi
        done
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
    REASON_LINES+="[Missing AGENTS.md]\\n"
    echo "================================================================" >&2
    echo "CHECK 2: MISSING AGENTS.md CHECK" >&2
    echo "" >&2
    echo "The following directories have 5 or more files but NO AGENTS.md" >&2
    echo "anywhere in their directory tree:" >&2
    echo "" >&2
    for entry in "${MISSING_AGENTS[@]}"; do
        REASON_LINES+="  - $entry\\n"
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

# AIDEV-NOTE: permissionDecision "ask" delegates to the user — they see the
# warnings above and approve/deny interactively. The LLM cannot bypass this.
cat <<EOF
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": "${REASON_LINES}Approve to commit as-is, or deny to fix first."}}
EOF
exit 0
