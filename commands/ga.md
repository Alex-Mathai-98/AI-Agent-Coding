# TASK: Generate Git Staging Command from Recent Context

Please perform the following actions to help me stage the changes we just made:

## 1. Context Analysis
Scan our conversation history moving backwards. Locate the most recent **"Task Start Point"**.
* *Definition of Task Start Point:* The user prompt that initiated the specific feature, bug fix, or refactor we are currently working on.
* *Constraint:* Ignore any conversation turns or file changes that occurred *before* this specific request (i.e., ignore previous, completed tasks within this same chat session).

## 2. Change Detection
Review all actions taken since that Start Point. Compile a list of every file that was:
* **Created** (New files)
* **Modified** (Edited existing files)
* **Deleted** (Files removed)

## 3. Command Generation
Construct a single `git add` command string that includes all identified file paths.
* **Formatting:** Ensure all file paths are wrapped in quotes (e.g., `'path/to/file.js'`) to handle potential spaces in filenames.
* **Syntax:** The command should look like: `git add 'file1.ext' 'file2.ext' 'file3.ext'`
* *Note:* If a file was deleted, ensure the command uses the appropriate git syntax to stage that deletion (usually `git add` works, or `git rm` if you prefer, but keep it to one single line if possible).

## 4. Output Generation
Write this command string into a new text file named **`git_stage_command.txt`**.
* **Do not** execute the command.
* **Do not** include any other text, markdown, or explanations inside the text file—only the raw command.

Once created, confirm the file exists and display the content of the command here in the chat for review.