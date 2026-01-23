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

## Enabling Notifications

Get notified on your Mac when Claude Code completes a task. Choose the setup that matches your environment.

---

### Option 1: Local Mac + Remote Server (VS Code Remote SSH)

**Use Case:** You're running Claude Code on a remote Linux server via VS Code's Remote SSH extension, and want notifications on your Mac laptop.

#### Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  LOCAL MAC              SSH (VS Code Remote)         REMOTE SERVER          │
│  (Your Laptop)     ◄──────────────────────────►      (Linux)                │
│                                                                             │
│  • VS Code runs here                                 • Claude Code runs     │
│  • LaunchAgent here                                    here                 │
│  • Notifications                                     • Your code lives      │
│    appear here                                         here                 │
│         │                                                   │               │
│         │ Listens to channel                 Posts to       │               │
│         ▼                                    channel        ▼               │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                        ntfy.sh (Cloud)                               │  │
│  │                     Message Relay Service                            │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Key distinction:**

| Machine | What it is | Terminal type |
|---------|------------|---------------|
| **Local Mac** | Your physical laptop sitting in front of you | Mac Terminal (Terminal.app, iTerm2) |
| **Remote Server** | Linux server you SSH into | VS Code integrated terminal (runs on remote) |

> **Important:** The VS Code integrated terminal runs commands **on the remote server**, not on your Mac.

---

#### Step A: Cloud Setup (ntfy.sh)

Visit [ntfy.sh](https://ntfy.sh) and create a unique channel name (e.g., `my-claude-notifications-12345`).

Keep this name private — anyone with the channel name can send/receive messages.

---

#### Step B: Local Mac Setup

> **Where:** All commands in this section run in **Mac Terminal** (Terminal.app or iTerm2) — NOT the VS Code terminal

**B1. Create the LaunchAgent plist file**

```bash
nano ~/Library/LaunchAgents/com.ntfy.listener.plist
```

Paste the following content (replace `YOUR-CHANNEL-NAME` with your actual channel):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ntfy.listener</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>while true; do curl -s "https://ntfy.sh/YOUR-CHANNEL-NAME/raw" | while read msg; do osascript -e "display notification \"$msg\" with title \"Claude Code\""; done; sleep 5; done</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/ntfy-listener.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/ntfy-listener.err</string>
</dict>
</plist>
```

**B2. Load the LaunchAgent**

```bash
# Load (starts immediately and on every login)
launchctl load ~/Library/LaunchAgents/com.ntfy.listener.plist

# Verify it's running
launchctl list | grep ntfy
```

**B3. Useful commands**

```bash
# Unload (stop) the listener
launchctl unload ~/Library/LaunchAgents/com.ntfy.listener.plist

# Check logs if something isn't working
cat /tmp/ntfy-listener.log
cat /tmp/ntfy-listener.err
```

---

#### Step C: Remote Server Setup

> **Where:** All commands in this section run on the **Remote Server** — use VS Code's integrated terminal

**C1. Create Claude Code settings file**

Create/edit `~/.claude/settings.json` on the remote server:

```bash
mkdir -p ~/.claude
nano ~/.claude/settings.json
```

Paste the following content (replace `YOUR-CHANNEL-NAME` with your actual channel):

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline-command.sh"
  },
  "alwaysThinkingEnabled": true,
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "printf '\\a' > /dev/tty 2>/dev/null"
          },
          {
            "type": "command",
            "command": "curl -s -d 'Claude Code finished' ntfy.sh/YOUR-CHANNEL-NAME"
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "printf '\\a' > /dev/tty 2>/dev/null"
          },
          {
            "type": "command",
            "command": "curl -s -d 'Claude Code Notification' ntfy.sh/YOUR-CHANNEL-NAME"
          }
        ]
      }
    ]
  }
}
```

**C2. Create the statusline command script (optional)**

If you want a custom status line showing the current directory, git branch, daily git stats, and model name, create `~/.claude/statusline-command.sh`:

```bash
nano ~/.claude/statusline-command.sh
```

Paste the following content:

```bash
#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Get current working directory
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Store original cwd for git operations before any modifications
original_cwd="$cwd"

# Contract home directory to ~ (tilde expansion)
home_dir="$HOME"
if [[ "$cwd" == "$home_dir"* ]]; then
  cwd="~${cwd#$home_dir}"
fi

# Shorten intermediate directories (keep first char only, preserve first and last 2 segments)
# Example: ~/development/long/tree/root/Kernel_Playground/Kernel_Agent -> ~/development/l/t/r/Kernel_Playground/Kernel_Agent
shorten_path() {
  local path="$1"
  local prefix=""

  # Handle ~ prefix
  if [[ "$path" == "~"* ]]; then
    prefix="~"
    path="${path#\~}"
  fi

  # Split path into segments
  IFS='/' read -ra segments <<< "$path"

  # Remove empty first element (from leading /)
  if [[ -z "${segments[0]}" ]]; then
    segments=("${segments[@]:1}")
  fi

  local count=${#segments[@]}

  # If 4 or fewer segments, no shortening needed
  if [[ $count -le 4 ]]; then
    echo "${prefix}${path}"
    return
  fi

  # Keep first segment full, shorten middle segments, keep last 2 full
  local result="${segments[0]}"
  for ((i=1; i<count-2; i++)); do
    result="$result/${segments[i]:0:1}"
  done
  result="$result/${segments[count-2]}/${segments[count-1]}"

  echo "${prefix}/${result}"
}

cwd=$(shorten_path "$cwd")

# Get model ID (extract just the id field if it's a JSON object/array)
model=$(echo "$input" | jq -r '.model | if type == "array" then .[0].id elif type == "object" then .id else . end // empty')

# Shorten common model names for display
shorten_model() {
  local m="$1"
  case "$m" in
    claude-opus-4-5-*) echo "Opus-4.5" ;;
    claude-sonnet-4-5-*) echo "Sonnet-4.5" ;;
    claude-sonnet-4-*) echo "Sonnet-4" ;;
    claude-3-5-sonnet-*) echo "Sonnet-3.5" ;;
    claude-3-opus-*) echo "Opus-3" ;;
    claude-3-sonnet-*) echo "Sonnet-3" ;;
    claude-3-haiku-*) echo "Haiku-3" ;;
    *) echo "$m" ;;
  esac
}
model=$(shorten_model "$model")

# Get git branch name if in a git repository
# Use --no-optional-locks to avoid lock contention
# Use original_cwd (not shortened path) for actual git operations
branch=$(cd "$original_cwd" 2>/dev/null && git --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)

# Get daily git statistics (lines added/removed today)
git_stats=""
if [ -n "$branch" ]; then
  # Get today's date in the format git log uses
  today=$(date +%Y-%m-%d)

  # Count lines added and removed in commits from today
  # Use --no-optional-locks to avoid lock contention
  stats=$(cd "$original_cwd" 2>/dev/null && git --no-optional-locks log --since="$today 00:00:00" --until="$today 23:59:59" --pretty=tformat: --numstat 2>/dev/null | awk '{added+=$1; removed+=$2} END {printf "+%d/-%d", added, removed}')

  if [ -n "$stats" ] && [ "$stats" != "+0/-0" ]; then
    git_stats="$stats"
  fi
fi

# Build status line
# Current directory in bold blue
status=$(printf '\033[01;34m%s\033[00m' "$cwd")

# Add git branch in green if available
if [ -n "$branch" ]; then
  status="$status $(printf '\033[00;32m(%s)\033[00m' "$branch")"

  # Add daily git stats in cyan if available
  if [ -n "$git_stats" ]; then
    status="$status $(printf '\033[00;36m[%s]\033[00m' "$git_stats")"
  fi
fi

# Add model ID in magenta if available
if [ -n "$model" ]; then
  status="$status $(printf '\033[00;35m[%s]\033[00m' "$model")"
fi

echo "$status"
```

Make it executable:

```bash
chmod +x ~/.claude/statusline-command.sh
```

**What the statusline shows:**
- **Current directory** (bold blue) - shortened for long paths
- **Git branch** (green) - if in a git repo
- **Daily git stats** (cyan) - lines added/removed today
- **Model name** (magenta) - shortened model identifier

**C3. What each hook does**

| Hook | Trigger | Actions |
|------|---------|---------|
| `Stop` | Claude Code completes a task | 1. Rings terminal bell<br>2. Sends notification to ntfy.sh |
| `Notification` | Claude Code sends a notification | 1. Rings terminal bell<br>2. Sends notification to ntfy.sh |

**C4. Manual test (optional)**

```bash
# Send a test notification from the remote server
curl -d "Test from remote server" ntfy.sh/YOUR-CHANNEL-NAME
```

---

#### Test the Full Setup

| Step | Location | Action |
|------|----------|--------|
| 1 | Local Mac | Verify listener: `launchctl list \| grep ntfy` |
| 2 | Remote Server | Send test: `curl -d "Test" ntfy.sh/YOUR-CHANNEL-NAME` |
| 3 | Local Mac | Confirm macOS notification appears |

---

#### How It Works

```
REMOTE SERVER                    ntfy.sh                     LOCAL MAC
─────────────                    ───────                     ─────────
Claude Code completes    ──►    Message stored    ──►    LaunchAgent receives
        │                       in channel                      │
        ▼                                                       ▼
curl posts to channel           Cloud relay              osascript triggers
                                service                  macOS notification
```

1. **Remote Server:** Claude Code hook sends a message via `curl` to ntfy.sh
2. **ntfy.sh Cloud:** Message is stored and relayed to all channel listeners
3. **Local Mac:** LaunchAgent receives the message and triggers macOS notification

---

### Option 2: Local Mac Only (VS Code on Local Folder)

**Use Case:** You're running Claude Code directly on your Mac with VS Code open on a local folder. Everything runs on the same machine.

#### Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           LOCAL MAC (Your Laptop)                           │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  VS Code                                                            │   │
│  │  • Opens local folder                                               │   │
│  │  • Integrated terminal runs Claude Code                             │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    │ Hook triggers on completion            │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  macOS Native                                                       │   │
│  │  • afplay plays sound                                               │   │
│  │  • osascript shows notification                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Key point:** No cloud relay needed — everything happens locally on your Mac.

---

#### Setup

> **Where:** All commands run in **Mac Terminal** (Terminal.app, iTerm2, or VS Code's integrated terminal — they're all on the same machine)

**1. Create Claude Code settings file**

Create/edit `~/.claude/settings.json`:

```bash
mkdir -p ~/.claude
nano ~/.claude/settings.json
```

Paste the following content:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline-command.sh"
  },
  "alwaysThinkingEnabled": true,
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "afplay /System/Library/Sounds/Glass.aiff & osascript -e 'display notification \"Claude has finished\" with title \"Claude Code\"'"
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "afplay /System/Library/Sounds/Glass.aiff & osascript -e 'display notification \"Claude needs your attention\" with title \"Claude Code\"'"
          }
        ]
      }
    ]
  }
}
```

**2. Create the statusline command script (optional)**

If you want the custom status line, create `~/.claude/statusline-command.sh` with the same content as in Option 1 (see [Step C2 above](#c2-create-the-statusline-command-script-optional)).

```bash
chmod +x ~/.claude/statusline-command.sh
```

---

#### What Each Hook Does

| Hook | Trigger | Actions |
|------|---------|---------|
| `Stop` | Claude Code completes a task | 1. Plays Glass sound<br>2. Shows "Claude has finished" notification |
| `Notification` | Claude Code sends a notification | 1. Plays Glass sound<br>2. Shows "Claude needs your attention" notification |

---

#### How It Works

```
LOCAL MAC
─────────
Claude Code completes
        │
        ▼
Hook executes command
        │
        ├──► afplay plays /System/Library/Sounds/Glass.aiff
        │
        └──► osascript displays macOS notification
```

1. **Claude Code** finishes a task and triggers the `Stop` hook
2. **afplay** plays the Glass sound effect (runs in background with `&`)
3. **osascript** displays a native macOS notification

---

#### Available macOS Sounds

You can change `Glass.aiff` to any of these built-in sounds:

```
/System/Library/Sounds/
├── Basso.aiff
├── Blow.aiff
├── Bottle.aiff
├── Frog.aiff
├── Funk.aiff
├── Glass.aiff      ← Default in config
├── Hero.aiff
├── Morse.aiff
├── Ping.aiff
├── Pop.aiff
├── Purr.aiff
├── Sosumi.aiff
├── Submarine.aiff
└── Tink.aiff
```

Test a sound: `afplay /System/Library/Sounds/Hero.aiff`

---

### Settings Precedence

Claude Code uses a five-level scope system where **higher scopes override lower ones**:

| Priority | Scope | Location |
|----------|-------|----------|
| 1 (lowest) | User | `~/.claude/settings.json` |
| 2 | Project | `.claude/settings.json` (in project root) |
| 3 | Local | `.claude/settings.local.json` (in project root) |
| 4 | CLI args | Command line arguments |
| 5 (highest) | Managed | System-deployed `managed-settings.json` |

#### How This Applies to Your Setup

| Scope | File | Description |
|-------|------|-------------|
| User | `~/.claude/settings.json` | Host-level settings (configured in Option 1 or 2 above) |
| Project | `.claude/settings.json` | Project-specific settings (committed to git) |
| Local | `.claude/settings.local.json` | Personal overrides (not committed to git) |

**Rule:** Project-level takes precedence over host-level. If both define the same setting, the project setting wins.

#### How Merging Works

- **Settings are merged**, not completely replaced
- If project settings don't specify something, user settings still apply
- **Deny rules always win** over allow rules, even across scopes

#### Hooks Behavior

Hooks follow the same precedence:
- Your host-level hooks (like notification sounds and ntfy.sh) will run **unless** a project-level hook overrides them for the same event
- If a project defines a `Stop` hook, it replaces (not appends to) the user-level `Stop` hook

#### Example: Local Overrides

Create `.claude/settings.local.json` in a project for personal overrides that aren't committed to git:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Custom notification for this project only'"
          }
        ]
      }
    ]
  }
}
```

This takes precedence over both user (`~/.claude/settings.json`) and project (`.claude/settings.json`) settings.

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




