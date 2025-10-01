# AI-Agent-Coding



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




