---
name: wrap
description: Clean handoff when ending a session — commits WIP, logs progress, and summarizes for the next agent
disable-model-invocation: true
---

# /wrap — Clean Session Handoff

Run this when you're ending a session (context window getting large, need to stop, or switching tasks). This ensures nothing is lost and the next agent can pick up seamlessly.

## Step 1: Read RALPH.md

Read `RALPH.md` from the project root. You need:
- **Quality Commands** — specifically the typecheck command
- **Testing section** — `test_plan` path and `test_progress` path (if configured)
- **Documents section** — `prd` path, `issues` path

If `RALPH.md` is missing, warn the user and still attempt to commit and summarize what you can.

## Step 2: Detect Workflow

Check which workflow is active:
1. Read the test plan file (path from RALPH.md Testing.test_plan) — if it exists and has incomplete tests (`passes: null`), you're in a **testing workflow**
2. Read `scripts/ralph/prd.json` — if it exists and has incomplete stories (`passes: false`), you're in a **dev sprint workflow**
3. If both exist, determine which one you were actively working on based on the current branch and recent activity

Then follow the matching section below.

## Dev Sprint Workflow

### Assess Current Work

Silently check:
1. `git status` — any uncommitted changes?
2. `git diff --stat` — what files were modified?
3. Read `scripts/ralph/prd.json` — which story was being worked on? (first story where `passes: false`)
4. Run the typecheck command from RALPH.md Quality Commands — does the current code compile?

### Commit Work-in-Progress

If there are uncommitted changes:

1. Stage all modified and new files (but NOT .env files)
2. Determine the current story being worked on from prd.json
3. Create a WIP commit:
   ```
   wip: [STORY-ID] - [brief description of what was done]
   ```
4. If typecheck fails, still commit — the next agent will fix it. Note the errors in the handoff.

If there are NO uncommitted changes, skip to the log step.

### Log Handoff

Append a handoff entry to `scripts/ralph/progress.txt`:

```
## [Date] - [STORY-ID] (HANDOFF - session ended mid-story)
- **What was completed:**
  - [list what was built/changed]
- **What remains:**
  - [list what still needs to be done from the acceptance criteria]
- **Current state:**
  - Typecheck: [passing/failing — if failing, list the errors]
  - Files modified: [list key files]
- **Notes for next agent:**
  - [any context that would help: approaches tried, gotchas hit, decisions made]
---
```

### Output Summary

```
## Session Wrapped

Story: [STORY-ID] - [title]
Status: In progress (not yet complete)
Commit: [wip commit hash and message]

### What was done:
- [bullet points]

### What remains:
- [bullet points]

### For next session:
Run /start to pick up where this left off. The next agent will see
the WIP commit and handoff notes automatically.
```

## Testing Workflow

### Assess Current Work

Silently check:
1. `git status` — any uncommitted changes? (could be blocker fixes or test plan updates)
2. `git diff --stat` — what files were modified?
3. Read the test plan file (path from RALPH.md Testing.test_plan) — what's the `current` test case? How many passed/failed/remaining?
4. Read the issues file (path from RALPH.md Documents.issues) — any open issues?

### Commit Work-in-Progress

If there are uncommitted changes:

1. Stage all modified and new files (but NOT .env files)
2. Create a WIP commit:
   ```
   wip: testing - [current test case ID] - [brief description]
   ```
   Example: `wip: testing - TC-14 - fixed auth blocker, 13/27 tests done`

If there are NO uncommitted changes, skip to the log step.

### Log Handoff

Append a session entry to the test progress file (path from RALPH.md Testing.test_progress):

```
## [Date] - Testing Session (HANDOFF - session ended mid-testing)
- **Device**: [device from test plan]
- **Tests run**: TC-XX through TC-YY
- **Results**: [passed] passed, [failed] failed, [remaining] remaining
- **Blockers fixed**: [list or "none"]
- **Issues logged**: [count new issues this session]
- **Next up**: TC-ZZ — [title]
- **Notes for next agent:**
  - [any context: app state, what was being investigated, etc.]
---
```

### Output Summary

```
## Session Wrapped

Testing: [test plan name]
Progress: [passed]/[total] passed, [failed] failed, [remaining] remaining
Current: [current test case ID] — [title]
Commit: [wip commit hash and message, if any]

### This session:
- Tests completed: [list]
- Issues found: [count]
- Blockers fixed: [count or "none"]

### For next session:
Run /start to pick up where this left off. The next agent will see
the active test plan and continue from [current test case].
```

## Important Rules

- ALWAYS commit before wrapping, even if the code is broken — losing work is worse than a broken WIP commit
- NEVER mark a story as `passes: true` or a test as `passes: true` unless it genuinely passed
- NEVER delete or replace existing progress/log content — only append
- Keep handoff notes specific and actionable
- In testing workflow, always update the test plan file with the current state before committing
