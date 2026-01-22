# Code Test

Generate or modify tests based on a plan file or user instructions.

## Step 1: Identify what to test

Check for a test plan file (`z-cpl-*-only-test.md`) from the conversation, or use user instructions directly.

User instructions: $ARGUMENTS

If no plan file and no instructions, ask the user what to test.

## Step 2: Generate meaningful tests

**Follow the FAIL-FAST test runner pattern:**
Read `tests/bash_files/sample_code/example_test.py` as the structural template. Key requirements:
- Let `AssertionError` propagate naturally—do NOT catch and count failures
- No try/except around test invocations—a failing test must exit with non-zero code
- If any test fails, the script exits immediately with code 1

**Prioritize complexity over coverage of trivial code.**
- Focus on complex functions, business logic, and integration points
- Skip trivial code: simple getters, setters, one-liner wrappers
- A few good tests on critical paths beat many useless tests on boilerplate

**Test real behavior, not implementation details.**
- Test inputs → outputs and side effects
- Avoid testing internal method calls or private state

## Step 3: Run tests and interpret failures correctly

After generating tests, run them. When a test fails:

**STOP. Do not assume the test is wrong.**

A failing test may indicate:
1. A bug in the implementation (the test is doing its job)
2. A technical issue in the test itself

**Only modify the test if the failure is due to:**
- Missing imports
- Syntax errors
- Wrong data types
- Incorrect test setup (e.g., missing fixtures, wrong mocks)
- Other non-functionality-related errors

**If the test fails due to actual functionality (the code under test behaves differently than expected):**
- Do NOT auto-fix the test to make it pass
- Present the failure to the user
- Ask: "Should I fix the test expectation, or is this a bug in the implementation that needs fixing?"

## Step 4: Integrate new tests into CI pipeline

If a completely new test file was created, it must be added to the CI pipeline.

**Reference the template:**
Read `tests/bash_files/sample_code/test_example_template.sh` to understand the structure. Create a new bash script that mimics this template to invoke the new test file and record its exit code.

**Determine the correct location:**
- Identify which subfolder of `src/` the code under test belongs to
- Place the new bash script in the corresponding subfolder under `tests/bash_files/`
- Example: testing code in `src/folder_A/` → bash script goes in `tests/bash_files/folder_A/`
- If the subfolder already exists, add only the new bash file
- If the subfolder doesn't exist, create it first

**Update the CI pipeline:**
Read `tests/bash_files/run_all_tests.sh` and check if modifications are needed to invoke the newly added bash script. Add the necessary invocation if missing.

## After generating tests

Summarize:
1. What was tested
2. Test results (pass/fail)
3. Any failures requiring user decision
4. CI integration changes made (new bash script location, run_all_tests.sh updates)