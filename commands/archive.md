# Archive Plan Files

Archive plan files by renaming them to meaningful names and moving them to the `claude_plans/` directory.

## Arguments

$ARGUMENTS

If no arguments are provided, find all `z-cpl-*.md` files in the project root directory.

## Instructions

For each plan file provided (or found):

### 1. Read and Analyze the File
- Read the file content
- Extract the title from the first heading (e.g., `# Code Plan: Some Feature Name`)
- If no title is found, use the first non-empty line or ask the user for a name

### 2. Generate Meaningful Filename
- Take the title after "Code Plan:" (or entire title if no colon)
- Convert to kebab-case (lowercase, spaces/underscores → hyphens)
- Remove special characters except hyphens
- Ensure filename ends with `.md`
- Examples:
  - `# Code Plan: Save Individual Tool Reflections` → `save-individual-tool-reflections.md`
  - `# Implement User Authentication` → `implement-user-authentication.md`

### 3. Check for Conflicts
- If a file with the same name exists in `claude_plans/`:
  - Append a number suffix: `filename-2.md`, `filename-3.md`, etc.
  - Or ask the user if they want to overwrite

### 4. Move the File
- Use `git mv` if the file is tracked by git, otherwise use regular `mv`
- Move from current location to `claude_plans/<new-name>.md`

### 5. Report Results
For each file processed, report:
- Original path
- New path
- Whether move was successful

## Example Usage

```
# Archive a single file
/archive z-cpl-29.md

# Archive multiple files
/archive z-cpl-29.md z-cpl-37.md z-cpl-41.md

# Archive all z-cpl files (no arguments)
/archive
```

## Output Format

```
Archived plan files:
  z-cpl-29.md → claude_plans/save-individual-tool-reflections.md ✓
  z-cpl-37.md → claude_plans/implement-retry-logic.md ✓
  z-cpl-41.md → claude_plans/fix-memory-leak.md ✓

3 files archived successfully.
```
