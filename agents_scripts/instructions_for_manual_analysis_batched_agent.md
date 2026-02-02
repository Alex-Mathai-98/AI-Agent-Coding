### Instructions for Batched Manual Analysis

This document outlines the requirements and execution steps for running high-reasoning data analysis using the `@opus-manual-analysis-batched` agent. This version processes multiple files per session using a **manifest file** that specifies exact input/output/instructions paths for each data point.

## 1. Prerequisites

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

The `analysis_folder` and `logs` directories **must be created before** invoking the agent.

```bash
mkdir -p <PATH_TO_PARENT>/analysis_folder
mkdir -p <PATH_TO_PARENT>/logs
```

This is handled automatically in the invocation script below.

---

## 2. Invocation Steps

### Step 1: Define Your Criteria

Write your labels and logic into the `instructions.md` file.

* *Example:* "Compare the patches. Categories: [Identical, Superset, Subset, Different]. Logic: Ignore trivial edits like comments."

### Step 2: Execute Parallel Batched Run

Run the command below. Replace `<PATH_TO_DATA_FOLDER>` with the path to the folder containing your JSON files.

```bash
DATA_FOLDER="<PATH_TO_DATA_FOLDER>"
PARENT_FOLDER="$(dirname "$DATA_FOLDER")"
INSTRUCTIONS_FILE="$PARENT_FOLDER/instructions.md"
ANALYSIS_FOLDER="$PARENT_FOLDER/analysis_folder"
BATCH_SIZE="${BATCH_SIZE:-5}"     # Files per session (default 5)
MAX_FILES="${MAX_FILES:-0}"       # 0 = no limit; set to N to process at most N files
PARALLEL="${PARALLEL:-4}"         # Parallel sessions (default 4)
mkdir -p "$ANALYSIS_FOLDER"
mkdir -p "$PARENT_FOLDER/logs"
mkdir -p "$PARENT_FOLDER/manifests"
: > "$PARENT_FOLDER/logs/success.log"
: > "$PARENT_FOLDER/logs/failure.log"

# AIDEV-NOTE: deterministic file listing, skip already-processed, optional cap
# AIDEV-NOTE: -maxdepth 1 -type f prevents matching directories or nested files
_list_files() { find "$DATA_FOLDER" -maxdepth 1 -name "*.json" -type f | sort; }
_maybe_limit() { if [ "$MAX_FILES" -gt 0 ] 2>/dev/null; then head -n "$MAX_FILES"; else cat; fi; }

# Build list of unprocessed files (resume-safe: skips files with existing output)
PENDING_FILES=()
while IFS= read -r file; do
    file="${file// /}"
    [ -z "$file" ] && continue
    basename_no_ext="$(basename "${file%.json}")"
    output_file="$ANALYSIS_FOLDER/${basename_no_ext}_analysis.json"
    if [ ! -f "$output_file" ]; then
        PENDING_FILES+=("$file")
    fi
done < <(_list_files | _maybe_limit)

TOTAL=${#PENDING_FILES[@]}
echo "Total files to process: $TOTAL"
echo "Batch size: $BATCH_SIZE"
echo "Parallel sessions: $PARALLEL"
echo "Estimated sessions: $(( (TOTAL + BATCH_SIZE - 1) / BATCH_SIZE ))"

if [ "$TOTAL" -eq 0 ]; then
    echo "Nothing to do — all files already processed."
    exit 0
fi

# AIDEV-NOTE: manifest-based batching — each batch gets a .manifest file with 3 columns per line
batch_num=0
for (( i=0; i<TOTAL; i+=BATCH_SIZE )); do
    batch_num=$((batch_num + 1))
    manifest="$PARENT_FOLDER/manifests/batch_${batch_num}.manifest"
    : > "$manifest"
    for (( j=i; j<i+BATCH_SIZE && j<TOTAL; j++ )); do
        input_file="${PENDING_FILES[$j]}"
        [ -z "$input_file" ] && continue
        basename_no_ext="$(basename "${input_file%.json}")"
        output_file="$ANALYSIS_FOLDER/${basename_no_ext}_analysis.json"
        echo "${input_file}|${output_file}|${INSTRUCTIONS_FILE}" >> "$manifest"
    done
    echo "$batch_num|$manifest"
done | xargs -P "$PARALLEL" -I % bash -c '
    IFS="|" read -r batch_id manifest_path <<< "%"
    logfile="'"$PARENT_FOLDER"'/logs/batch_${batch_id}.log"
    readable_logfile="'"$PARENT_FOLDER"'/logs/batch_${batch_id}.readable.log"

    claude --verbose --agent opus-manual-analysis-batched --output-format stream-json -p "manifest_file: $manifest_path" > "$logfile" 2>&1

    # AIDEV-NOTE: post-process JSONL into human-readable log
    jq -r '"'"'
      if .type == "assistant" then
        .message.content[]? |
        if .type == "tool_use" then ">>> TOOL: \(.name) \(.input.file_path // (.input | tostring) | .[0:200])"
        elif .type == "text" then "--- TEXT ---\n\(.text)"
        else empty end
      elif .type == "user" then
        .message.content[]? |
        if .type == "tool_result" then "<<< RESULT:\n\(.content | tostring | split("\n") | map(gsub("^\\s*\\d+→\\s?"; "")) | map("    " + .) | join("\n"))"
        else empty end
      else empty end
    '"'"' "$logfile" > "$readable_logfile" 2>/dev/null

    # Post-batch: check which output files exist
    while IFS="|" read -r inp outp instr; do
        if [ -f "$outp" ]; then
            echo "$inp" >> "'"$PARENT_FOLDER"'/logs/success.log"
        else
            echo "$inp" >> "'"$PARENT_FOLDER"'/logs/failure.log"
        fi
    done < "$manifest_path"
'
```

### Tuning Parameters

| Variable     | Default | Description                                         |
| ------------ | ------- | --------------------------------------------------- |
| `BATCH_SIZE` | 5       | Number of files per agent session                   |
| `MAX_FILES`  | 0       | Cap on total files to process (0 = unlimited)       |
| `PARALLEL`   | 4       | Number of concurrent agent sessions                 |

```bash
# Example: 8 files per batch, 2 parallel sessions, max 50 files
BATCH_SIZE=8 PARALLEL=2 MAX_FILES=50 bash -c '<paste the script above>'
```

**Guidance on batch size:**
- **5** (default): Conservative, minimal context growth, safest quality.
- **8**: Good balance for simple classification tasks.
- **10+**: Only if your per-file JSON is small and analysis is straightforward.

### Real-Time Monitoring

While the parallel run is in progress, open a second terminal and use `watch` to track live success/failure counts:

```bash
# Replace <PATH_TO_PARENT> with your actual parent folder path
watch -n 5 'echo "SUCCESS: $(wc -l < <PATH_TO_PARENT>/logs/success.log) | FAIL: $(wc -l < <PATH_TO_PARENT>/logs/failure.log) | TOTAL: <N>"'
```

After the run completes, `failure.log` lists every input file whose agent did not produce an output — useful for investigation and re-runs.

---

## 3. Output Organization

1. **Input files**: The JSON files to analyze, referenced in manifest files.
2. **Output files**: Written to exact paths specified in the manifest (typically `<PARENT>/analysis_folder/<basename>_analysis.json`).
3. **Instructions file**: Referenced in each manifest line.
4. **Manifest files**: `<PARENT>/manifests/batch_<N>.manifest` — one per batch, 3 pipe-delimited columns per line.
5. **Execution Logs**: Per-batch logs saved to `<PARENT>/logs/batch_<N>.log`.
6. **Success Log**: `<PARENT>/logs/success.log` — one line per input file that produced an output.
7. **Failure Log**: `<PARENT>/logs/failure.log` — one line per input file that did NOT produce an output.

---

## 4. Troubleshooting

* **Resuming Work**: The script checks for existing analysis files before building batches. Re-running will only process missing files.
* **Rate Limiting**: If you hit rate limits, reduce `PARALLEL` (e.g., `PARALLEL=2`) or increase `BATCH_SIZE`.
* **Quality Concerns**: If analysis quality degrades, reduce `BATCH_SIZE` to 3-4.
* **Partial Batch Failures**: If an agent session crashes mid-batch, some files in that batch may have been written. The resume logic handles this — re-running picks up only the missing ones.
* **Comparing with Original**: You can run the original `@opus-manual-analysis-2` agent (1:1) on failed files for a targeted retry.
