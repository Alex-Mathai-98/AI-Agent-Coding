### Instructions for Manual Analysis

This document outlines the requirements and execution steps for running high-reasoning data analysis using the `@opus-manual-analysis` agent in parallel.

## 1. Prerequisites

Before invoking the agent, ensure your data is structured as follows:

### Data File Requirements

* **Input Format**: Individual JSON files.
* **Content**: Each file should represent a single "unit of analysis" containing all data points necessary for the agent to make a decision based on your provided logic.
* **Consistency**: While the agent can handle various schemas, ensure the fields you intend to analyze exist across all files in your chosen folder.

> **Note:** The agent performs **1-to-1 analysis**. It does not look at other files in the directory during a single execution to maintain strict context isolation and data integrity.

---

## 2. Invocation Steps

### Step 1: Define Your Criteria

Determine your **Labels** and the **Logic** you want Opus to follow.

* *Example Labels:* `[Approved, Rejected, Needs Review]`
* *Example Logic:* "Label as 'Rejected' if the `total_cost` exceeds the `budget` field."

### Step 2: Execute Parallel Run

Run the command below. You must replace `<PATH_TO_YOUR_FOLDER>` with the actual path to your data directory.

```bash
find <PATH_TO_YOUR_FOLDER> -name "*.json" -not -path "*/analysis_folder/*" | while read -r file; do
    # Construct the expected analysis file path
    analysis_file="${file%/*}/analysis_folder/$(basename "${file%.json}")_analysis.json"
    
    # Only run Claude if the analysis file does NOT exist
    if [ ! -f "$analysis_file" ]; then
        echo "$file"
    fi
done | xargs -n 1 -P 4 -I % sh -c 'claude m "@opus-analyst analyze %: [LOGIC]" > %.log 2>&1'
```

---

## 3. Output Organization

The agent automatically manages the results based on the path provided during invocation:

1. **Infrastructure**: The agent identifies the parent folder of the JSON file and uses `mkdir -p` to create a subfolder named `analysis_folder` if it does not exist.
2. **Reasoning**: For every file, the agent generates a detailed, step-by-step explanation for why the data falls into its assigned category.
3. **Result Files**: Successful analyses are saved to `<PATH_TO_YOUR_FOLDER>/analysis_folder/<original_id>_analysis.json`.
4. **Execution Logs**: Individual logs (`<filename>.json.log`) are created in your current working directory to capture the agent's process and any potential errors.

---

## 4. Troubleshooting

* **Resuming Work**: The command is designed to skip files that already have a corresponding result in the `analysis_folder`. If the process stops, simply re-run the same command to finish the remaining files.
* **Concurrency**: If you experience rate limiting, change the `-P 4` flag to a lower number (e.g., `-P 2`) to reduce simultaneous requests.

---