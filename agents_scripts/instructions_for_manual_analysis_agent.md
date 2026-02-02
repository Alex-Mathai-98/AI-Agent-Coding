### Instructions for Manual Analysis (v2)

This document outlines the requirements and execution steps for running high-reasoning data analysis using the `@opus-manual-analysis-2` agent in parallel. In this version, the bash script derives and passes all three paths (`input_file`, `output_file`, `instructions_file`) explicitly to the agent.

## 1. Prerequisites

Before invoking the agent, ensure your data is structured as follows:

### Data File Requirements

* **Input Format**: Individual JSON files.
* **Content**: Each file should represent a single "unit of analysis" containing all data points necessary for the agent to make a decision based on your provided logic.
* **Consistency**: Ensure the fields you intend to analyze exist across all files in your chosen folder.
* **Instruction File**: A file named `instructions.md` **must** exist in the parent directory of your data folder (sibling to the data folder). This file contains your classification labels and logic.

### Required Permissions

The agent needs `Write` permission to write analysis files. This must be added to your project's `.claude/settings.local.json` (or `.claude/settings.json`) under `permissions.allow`:

```json
"Write"
```

**Note:** Claude Code permissions are global per project — there is no way to scope them to a specific agent. These permissions will apply to all agents and the main session.

### Output Folder Pre-creation (Required)

The `analysis_folder` and `logs` directories **must be created before** invoking the agent. Sub-agents may not have `Bash(mkdir:*)` permissions inherited from the parent session, so relying on the agent to create directories can cause permission prompts or failures.

```bash
mkdir -p <PATH_TO_PARENT>/analysis_folder
mkdir -p <PATH_TO_PARENT>/logs
```

This is handled automatically in the invocation script below.

> **Note:** The agent performs **1-to-1 analysis**. It does not look at other files in the directory during a single execution to maintain strict context isolation and data integrity.

---

## 2. Invocation Steps

### Step 1: Define Your Criteria

Write your labels and logic into the `instructions.md` file.

* *Example:* "Compare the patches. Categories: [Identical, Superset, Subset, Different]. Logic: Ignore trivial edits like comments."

### Step 2: Execute Parallel Run

Run the command below. Replace `<PATH_TO_DATA_FOLDER>` with the path to the folder containing your JSON files.

```bash
DATA_FOLDER="<PATH_TO_DATA_FOLDER>"
PARENT_FOLDER="$(dirname "$DATA_FOLDER")"
INSTRUCTIONS_FILE="$PARENT_FOLDER/instructions.md"
MAX_FILES="${MAX_FILES:-0}"   # 0 = no limit; set to N to process at most N files
mkdir -p "$PARENT_FOLDER/analysis_folder"
mkdir -p "$PARENT_FOLDER/logs"
: > "$PARENT_FOLDER/logs/success.log"
: > "$PARENT_FOLDER/logs/failure.log"

# AIDEV-NOTE: helper functions for deterministic file listing and optional cap
_list_files() { find "$DATA_FOLDER" -name "*.json" | sort; }
_maybe_limit() { if [ "$MAX_FILES" -gt 0 ] 2>/dev/null; then head -n "$MAX_FILES"; else cat; fi; }

TOTAL=$(_list_files | while read -r file; do
    basename_no_ext="$(basename "${file%.json}")"
    output_file="$PARENT_FOLDER/analysis_folder/${basename_no_ext}_analysis.json"
    if [ ! -f "$output_file" ]; then echo "$file"; fi
done | _maybe_limit | wc -l)
echo "Total files to process: $TOTAL"

_list_files | while read -r file; do
    basename_no_ext="$(basename "${file%.json}")"
    output_file="$PARENT_FOLDER/analysis_folder/${basename_no_ext}_analysis.json"
    log_file="$PARENT_FOLDER/logs/${basename_no_ext}.log"
    if [ ! -f "$output_file" ]; then
        echo "$file|$output_file|$INSTRUCTIONS_FILE|$log_file"
    fi
done | _maybe_limit | xargs -P 4 -I % bash -c '
    IFS="|" read -r input output instructions logfile <<< "%"
    claude -p "@opus-manual-analysis-2 input_file: $input output_file: $output instructions_file: $instructions" > "$logfile" 2>&1
    if [ -f "$output" ]; then
        echo "$input" >> "'"$PARENT_FOLDER"'/logs/success.log"
    else
        echo "$input" >> "'"$PARENT_FOLDER"'/logs/failure.log"
    fi
'
```

### Limiting the Number of Files

Set the `MAX_FILES` environment variable to cap how many files are processed in a single run. Files are sorted alphabetically for deterministic ordering.

```bash
# Process at most 10 files:
MAX_FILES=10 bash -c '<paste the script above>'

# Process all files (default):
bash -c '<paste the script above>'
```

### Real-Time Monitoring

While the parallel run is in progress, open a second terminal and use `watch` to track live success/failure counts:

```bash
# Replace <PATH_TO_PARENT> with your actual parent folder path
watch -n 5 'echo "SUCCESS: $(wc -l < <PATH_TO_PARENT>/logs/success.log) | FAIL: $(wc -l < <PATH_TO_PARENT>/logs/failure.log) | TOTAL: <N>"'
```

After the run completes, `failure.log` lists every input file whose agent did not produce an output — useful for investigation and re-runs.

---

## 3. Output Organization

The bash script derives all paths and passes them explicitly to the agent — the agent does not need to compute any paths itself.

1. **Input file**: The JSON file to analyze, passed as `input_file`.
2. **Output file**: Derived as `<PARENT>/analysis_folder/<basename>_analysis.json`, passed as `output_file`.
3. **Instructions file**: Derived as `<PARENT>/instructions.md`, passed as `instructions_file`.
4. **Execution Logs**: Individual logs saved to `<PARENT>/logs/<basename>.log`.
5. **Success Log**: `<PARENT>/logs/success.log` — one line per input file that produced an output.
6. **Failure Log**: `<PARENT>/logs/failure.log` — one line per input file that did NOT produce an output.

---

## 4. Troubleshooting

* **Resuming Work**: The script explicitly checks for existing analysis files in the output folder. If the process stops, re-running the command will only process the missing files, saving you time and tokens.
* **Concurrency**: If you experience rate limiting (429 errors), change the `-P 4` flag to a lower number (e.g., `-P 2`).
