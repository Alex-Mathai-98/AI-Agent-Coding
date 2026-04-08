#!/usr/bin/env bash
# AIDEV-NOTE: PreToolUse hook — fires before git commit to:
#   1. Warn about stale architecture.md files covering directories with modified code
#   2. Flag directories with >=8 files but no architecture.md
# Suggests running /arch-diagram. Outputs permissionDecision: "ask" when issues found.

set -euo pipefail

INPUT=$(cat)

# Extract the bash command from the tool input JSON
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$COMMAND" ] && exit 0

# Only trigger on commands that contain git commit
echo "$COMMAND" | grep -qE 'git\s+commit' || exit 0

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0

# AIDEV-NOTE: Only check staged files — same approach as check-agents-md.sh
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
# CHECK 1: Stale architecture.md — exists but not updated
# ============================================================
# AIDEV-NOTE: For each directory with staged changes, walk up to find the
# nearest architecture.md. If it exists but isn't staged, it's stale.
declare -A ARCH_MAP  # arch_file -> list of source dirs

for dir in "${!SEEN_DIRS[@]}"; do
    current="$dir"
    while [ "$current" != "." ] && [ "$current" != "/" ]; do
        candidate="$current/architecture.md"
        if [ -f "$REPO_ROOT/$candidate" ]; then
            if [ -z "${ARCH_MAP[$candidate]+x}" ]; then
                ARCH_MAP["$candidate"]="$dir"
            else
                ARCH_MAP["$candidate"]="${ARCH_MAP[$candidate]}, $dir"
            fi
            break
        fi
        current=$(dirname "$current")
    done
done

STALE_ARCH=()
for arch_file in "${!ARCH_MAP[@]}"; do
    if ! echo "$STAGED_FILES" | grep -qxF "$arch_file"; then
        STALE_ARCH+=("$arch_file")
    fi
done

if [ ${#STALE_ARCH[@]} -gt 0 ]; then
    FOUND_ISSUES=true
    REASON_LINES+="[Stale architecture.md]\\n"
    echo "================================================================" >&2
    echo "CHECK 1: STALE architecture.md" >&2
    echo "" >&2
    echo "The following architecture.md files cover directories with modified" >&2
    echo "code but were NOT updated in this commit:" >&2
    echo "" >&2
    for arch_file in "${STALE_ARCH[@]}"; do
        echo "  * $arch_file" >&2
        echo "    (covers changes in: ${ARCH_MAP[$arch_file]})" >&2
        REASON_LINES+="  $arch_file (covers: ${ARCH_MAP[$arch_file]})\\n"
    done
    echo "" >&2
    echo "SUGGESTION: Run /arch-diagram to update. For example:" >&2
    # Extract directory from first stale file
    first_stale_dir=$(dirname "${STALE_ARCH[0]}")
    echo "  /arch-diagram for $first_stale_dir" >&2
    echo "" >&2
fi

# ============================================================
# CHECK 2: Missing architecture.md — directory has >=8 files, no architecture.md
# ============================================================
MISSING_ARCH=()
for dir in "${!SEEN_DIRS[@]}"; do
    full_dir="$REPO_ROOT/$dir"
    [ -d "$full_dir" ] || continue

    # Skip if architecture.md exists in this directory
    [ -f "$full_dir/architecture.md" ] && continue

    # Count files in the directory (non-recursive)
    file_count=$(find "$full_dir" -maxdepth 1 -type f | wc -l)
    if [ "$file_count" -ge 8 ]; then
        MISSING_ARCH+=("$dir (${file_count} files)")
    fi
done

if [ ${#MISSING_ARCH[@]} -gt 0 ]; then
    FOUND_ISSUES=true
    REASON_LINES+="[Missing architecture.md]\\n"
    echo "================================================================" >&2
    echo "CHECK 2: MISSING architecture.md" >&2
    echo "" >&2
    echo "The following directories have 8 or more files but NO architecture.md:" >&2
    echo "" >&2
    for entry in "${MISSING_ARCH[@]}"; do
        REASON_LINES+="  - $entry\\n"
        echo "  * $entry" >&2
    done
    echo "" >&2
    echo "SUGGESTION: Run /arch-diagram for each directory above. For example:" >&2
    first_dir=$(echo "${MISSING_ARCH[0]}" | sed 's/ (.*//')
    echo "  /arch-diagram for $first_dir" >&2
    echo "" >&2
fi

# If no issues found, allow the commit
$FOUND_ISSUES || exit 0

# ============================================================
# Summary
# ============================================================
echo "================================================================" >&2
echo "ACTION: Approve to commit as-is, or deny to update/generate" >&2
echo "architecture docs first using /arch-diagram." >&2
echo "================================================================" >&2

# AIDEV-NOTE: permissionDecision "ask" delegates to the user — they see the
# warnings above and approve/deny interactively.
cat <<EOF
{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": "${REASON_LINES}Approve to commit as-is, or deny to update/generate architecture docs first."}}
EOF
exit 0
