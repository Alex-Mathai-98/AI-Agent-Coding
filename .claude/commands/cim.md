# Code Implement

Implement code based on a code plan.

## Step 1: Find the code plan

User instructions: $ARGUMENTS

**Option A — User specifies a plan file:**
If `$ARGUMENTS` references a specific plan file (e.g., `z-cpl-42.md`), locate that file. If the file cannot be found, stop and inform the user that the specified plan file does not exist.

**Option B — No file specified:**
If `$ARGUMENTS` does not reference a specific plan file, identify the `z-cpl-*.md` file created by the most recent `/cpl` command in this conversation. This is typically the immediately preceding step. Do NOT use `ls` or file system commands to find the "latest" plan—use only the conversation history.

If no code plan is found, stop and ask the user to run `/cpl` first or provide a valid plan file.

## Step 2: Check for test cases in the plan

Analyze the code plan for test-related work:

**If the plan contains ONLY test cases:** Stop and ask the user to invoke `/ct` instead—that command has specific instructions for test generation.

**If the plan contains BOTH implementation code AND test cases:** Split the plan into two files:
- `z-cpl-<NN>-no-test.md` — implementation only
- `z-cpl-<NN>-only-test.md` — test cases only

Then ask the user for permission to proceed with implementing `z-cpl-<NN>-no-test.md`. The test portion should be handled separately via `/ct`.

**If the plan contains NO test cases:** Proceed to Step 3.

## Step 3: Implement based on user instructions

Follow the user's instructions to implement the plan. If the plan contains multiple options, implement only the option(s) the user specifies.

## Implementation principles

Carry forward all principles from the code plan:
- **Avoid verbosity.** No excessive functions, long docstrings, or boilerplate. Small functions need no documentation—the code should speak for itself.
- **Simplicity first.** Smallest possible change. Human-readable code.
- **Reuse existing code.** Don't reimplement what exists.
- **Minimal abstractions.** No unnecessary classes or inheritance.
- **Let it fail.** No scattered try-catch. Exceptions propagate for debuggability.

## After implementation

Briefly summarize what was implemented and note any deviations from the plan (if any).