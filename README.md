# Claude Code Best Practices

A portable collection of Claude Code configurations, custom commands, and best practices. Clone this directly as your `.claude` folder in any project.

## Folder Structure

```
your-project/
├── .claude/
│   ├── commands/
│   ├── settings.json
│   └── ...
├── src/
│   └── ... (your project files)
├── tests/
│   ├── bash_files/
│   │   ├── run_all_tests.sh
│   │   └── run_tests_cron.sh
│   └── logs/
├── CLAUDE.md
└── pyproject.toml
```

## Setup

```bash
# 1. Navigate to your project root
cd ~/your-project

# 2. Clone this repo as .claude
git clone https://github.com/Alex-Mathai-98/AI-Agent-Coding.git .claude

# 3. Move the tests folder to project root (same level as .claude)
mv .claude/tests .

# 4. Update anytime
cd .claude && git pull
```

## Test Infrastructure Setup

### 1. Set up the environment

Run the prelude script from the project root:
```bash
source prelude.sh
```

### 2. Configure environment variables

Edit `dev.env` in the project root and set the following variables for email notifications:

```bash
# Email notification settings (for regression_email_notifier.py)

# Required - comma-separated recipient list
EMAIL_RECIPIENTS="to1@gmail.com,to2@gmail.com"

# Required - SMTP server settings
SMTP_HOST="smtp.gmail.com"
SMTP_PORT="587"
SMTP_USER="from@gmail.com"
SMTP_PASSWORD="<your-app-password>"

# Project settings
PROJECT_NAME="YOUR-PROJECT-NAME"
```

**Variable descriptions:**

| Variable | Description |
|----------|-------------|
| `EMAIL_RECIPIENTS` | Comma-separated list of email addresses to receive test notifications |
| `SMTP_HOST` | SMTP server hostname (e.g., `smtp.gmail.com` for Gmail) |
| `SMTP_PORT` | SMTP port (typically `587` for TLS) |
| `SMTP_USER` | Email account username for sending notifications |
| `SMTP_PASSWORD` | App password or SMTP password (for Gmail, use an App Password) |
| `PROJECT_NAME` | Project name displayed in email subjects (e.g., `[TEST FAILURES] MyProject Tests`) |

### 3. Verify the setup

Run the test suite to confirm everything works:
```bash
bash ./tests/run_tests_with_report.sh
```

This will run all tests and send email notifications if any failures occur.

---

### Claude Specific Notes

The /command will list all the available commands that Claude provides – like /init etc.

1. /init command to allow Claude to create the Claude.md file – this file has a high-level overview of the entire repository.

2. @filename for appending context – this command specifies the exact filename that would be needed for Claude when making edits.

3. /ide
This command allows Claude to automatically identify the correct context (so there is no need to specify @filename everytime), by looking at the currently open file in the IDE. You can see the words “In <filename>” at the extreme right to see what context Claude is considering.

4. shift+tab shift+tab
This enables the planning mode, where Claude first creates a plan before actually writing code. 
You can review the plan, make changes to the plan if needed. 
Then you can ask Claude to start making changes based on the plan by pressing shift+tab

5. /clear  - remove all the current accumulated context.

6. When writing instructions to Claude, you can press \ + enter to add text on a new line to make the prompt more visually appealing.

7. If you want to add a MCP server, you can run the command claude mcp add ...
The exact way to add the MCP server will be mentioned in the documentation of the MCP servers. {{Where is this documentation exactly ?}}

After adding a new MCP server, it will then be available (or get listed) using the /mcp command. You can select the mcp server and check the tools that the MCP server is currently providing.

8. In the .claude folder, you can add a commands subfolder, and insert a markdown file with some text. This will generate a new command in claude code for you.

9. Create the .trees folder and then add git worktrees in the trees folder. Each of these trees represent a separate features in the git worktrees.

git worktree add .trees/ui_feature
git worktree add .trees/testing_feature
git worktree add .trees/quality_feature

Create a terminal for each of these features and run /implement  for a feature in each of these worktrees.

Now use claude code to merge all the commits inside the .trees folder and fix any conflicts for you automatically !

Tips

1. When you want Claude to make visual changes, it is very powerful to paste a screenshot and then ask Claude to make the changes that you need – rather than describing those changes via text. Just paste the screenshot in the terminal of claude code.




