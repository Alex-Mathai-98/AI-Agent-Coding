### Instructions for Manual Analysis

This document outlines the requirements and execution steps for running high-reasoning data analysis using the `@opus-manual-analysis` agent in parallel.

## 1. Prerequisites

Before invoking the agent, ensure your data is structured as follows:

### Data File Requirements

* **Input Format**: Individual JSON files.
* **Content**: Each file should represent a single "unit of analysis" containing all data points necessary for the agent to make a decision based on your provided logic.
* **Consistency**: Ensure the fields you intend to analyze exist across all files in your chosen folder.
* **Instruction File**: A file named `instructions.md` **must** exist in the parent directory of your data folder (sibling to the data folder). This file contains your classification labels and logic.

> **Note:** The agent performs **1-to-1 analysis**. It does not look at other files in the directory during a single execution to maintain strict context isolation and data integrity.

---

## 2. Invocation Steps

### Step 1: Define Your Criteria

Write your labels and logic into the `instructions.md` file.

* *Example:* "Compare the patches. Categories: [Identical, Superset, Subset, Different]. Logic: Ignore trivial edits like comments."

### Step 2: Execute Parallel Run

Run the command below. Replace `<PATH_TO_DATA_FOLDER>` with the path to the folder containing your JSON files.

```bash
find <PATH_TO_DATA_FOLDER> -name "*.json" | while read -r file; do
    # Construct the expected sibling analysis file path
    analysis_file="${file%/*}/../analysis_folder/$(basename "${file%.json}")_analysis.json"
    
    # Only run Claude if the analysis file does NOT exist
    if [ ! -f "$analysis_file" ]; then
        echo "$file"
    fi
done | xargs -n 1 -P 4 -I % sh -c 'claude m "@opus-manual-analysis analyze %" > %.log 2>&1'

```

---

## 3. Output Organization

The agent automatically manages the results to maintain a clean sibling directory structure:

1. **Infrastructure**: The agent identifies the parent of your data folder and uses `mkdir -p` to create a sibling `analysis_folder` if it does not exist.
2. **Reasoning**: For every file, the agent generates a detailed, step-by-step explanation for the assigned category.
3. **Result Files**: Successful analyses are saved to `<PATH_TO_PARENT>/analysis_folder/<original_id>_analysis.json`.
4. **Execution Logs**: Individual logs (`<filename>.json.log`) are created in your **current terminal directory** to capture the process and errors.
5. **Instruction Loading**: The agent automatically reads classification logic from `<PARENT_FOLDER>/instructions.md`.

---

## 4. Troubleshooting

* **Resuming Work**: The command explicitly checks for existing analysis files in the sibling folder. If the process stops, re-running the command will only process the missing files, saving you time and tokens.
* **Concurrency**: If you experience rate limiting (429 errors), change the `-P 4` flag to a lower number (e.g., `-P 2`).