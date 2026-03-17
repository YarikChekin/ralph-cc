---
name: ralph
description: Show current Ralph sprint status and generate the kickoff prompt for a new agent session
disable-model-invocation: true
---

# /ralph — Sprint Status & Agent Kickoff

> **Tip:** Use `/start` instead for the full project assessment. `/ralph` just shows the dashboard and prompt directly.

When the user invokes `/ralph`, do the following:

## 1. Read Sprint State

Read these files (silently, don't dump their contents):
- `scripts/ralph/prd.json` — current sprint definition
- `scripts/ralph/progress.txt` — only the "Codebase Patterns" section at the top

## 2. Display Sprint Dashboard

Show a concise summary:

```
## Current Sprint: [description from prd.json]
Branch: [branchName]

| # | Story | Status |
|---|-------|--------|
| [priority] | [id] - [title] | [passes ? "Done" : "Pending"] |
...

Progress: [completed]/[total] stories
Next up: [first story where passes: false — show id + title]
```

If ALL stories have `passes: true`, show "ALL COMPLETE" and remind the user to review, merge, and archive.

## 3. Output the Kickoff Prompt

After the dashboard, output:

```
### Kickoff Prompt

Copy this into a new Claude Code session to start/continue the sprint:
```

Then output this exact prompt inside a code block:

```
Read RALPH.md first to understand project config (paths, commands, tech stack).

Your job is to execute the Ralph agent loop. Before writing any code, read these files to understand the project, the current sprint, and past learnings:

1. scripts/ralph/prompt.md — your full Ralph instructions (follow exactly)
2. scripts/ralph/prd.json — the current sprint and user stories
3. scripts/ralph/progress.txt — codebase patterns and learnings from past sprints (read the "Codebase Patterns" section carefully)
4. RALPH.md — project config, quality commands, document paths
5. CLAUDE.md — project overview (if it exists)
6. AGENTS.md — codebase conventions (if it exists)
7. Design doc from RALPH.md Documents.design (if configured)

After reading all context files, follow the Ralph prompt: pick the highest priority story where passes: false, implement it, run quality checks, commit, update the PRD, and log progress.

Work on ONE story per response. After completing a story, stop so I can review before continuing.

Start by reading the files above, then begin with the first incomplete story.
```
