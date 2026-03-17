---
name: start
description: Assess project state and pick up where the last session left off — the single entry point for any new session
disable-model-invocation: true
---

# /start — Project State Dispatcher

This is the first thing to run in any new session. It reads the project state, shows what's going on, and picks up where the last session left off.

## Step 1: Gather State (silently)

Read all of these before saying anything to the user.

**RALPH.md validation:** Before gathering any state, check that `RALPH.md` exists in the project root and has the required fields:
- `Project` section (Name must be non-empty)
- `Quality Commands` section (at least one command defined)
- `Documents` section (`prd` path must be defined)

If `RALPH.md` is missing entirely, show:
```
## Ralph Not Initialized

No RALPH.md found in this project.
```
And offer: "Run `/ralph-init` to set up ralph, or create RALPH.md manually."
Stop here — do not proceed to state gathering.

If `RALPH.md` exists but is missing required fields, show:
```
## RALPH.md Incomplete

Missing fields:
- [list each missing/empty required field]
```
And offer: "Run `/ralph-init` to reconfigure, or fill in the missing fields manually."
Stop here — do not proceed to state gathering.

**Once RALPH.md is validated**, read all paths from it and gather state:

1. Run `git status` — check for uncommitted changes, current branch
2. Run `git log --oneline -5` — see recent commits (look for `wip:` commits from interrupted sessions)
3. Read `scripts/ralph/prd.json` — current sprint, which stories pass/fail
4. Read the test plan file from RALPH.md Testing.test_plan (if configured) — active test plan, if any (check for incomplete test cases)
5. Read `scripts/ralph/progress.txt` — only the last entry (scroll to bottom) to see what was last done
6. Read the issues file from RALPH.md Documents.issues — check for bugs with status `Logged` (not yet fixed)
7. Read the backlog file from RALPH.md Documents.backlog — check for recent quick-capture entries (status: `Idea — quick capture`)

## Step 2: Determine Situation & Act

Based on what you found, follow the FIRST matching case.

**Logged Items Check** — regardless of which case matches, if the issues file has bugs with status `Logged`, or the backlog file has entries with status `Idea — quick capture`, append this after the case-specific dashboard:

```
### Logged Items
- [N] open bug(s) in [issues file path]
- [N] improvement idea(s) in [backlog file path]
```

Only show this section if there are items. If either file has no entries or doesn't exist, omit that line.

### Case A: Uncommitted changes exist

Show:
```
## Uncommitted Work Detected

Branch: [current branch]
Modified files: [list from git status]
Last commit: [most recent commit message]
```

Then run `git diff --stat` and summarize what the changes look like.

Ask the user: "You have uncommitted changes. What would you like to do?"
- **Review and commit** — show the diff, help craft a commit message
- **Discard and start fresh** — only if user explicitly confirms
- **Continue working** — the changes stay, proceed to Case B/C/D assessment

### Case B: Active sprint with WIP commit (interrupted session)

A `wip:` commit in recent history means the previous agent was interrupted mid-story. Parse the story ID from the WIP commit message format: `wip: [STORY-ID] - [description]`.

Show:
```
## Interrupted Sprint — Picking Up Where Left Off

Sprint: [description]
Branch: [branchName]
Last agent was working on: [story ID parsed from wip commit message]
WIP commit: [commit message]

| # | Story | Status |
|---|-------|--------|
...

Progress: [completed]/[total] stories
```

Read the last progress.txt entry and show a brief summary of the handoff notes (what was done, what remains).

Then ask: "Ready to pick up [STORY-ID] where the last session left off?"

If the user confirms, proceed to **Start Working** with this extra context:

```
IMPORTANT: The previous agent was interrupted mid-work on [STORY-ID].
There is a WIP commit: "[commit message]".
Check progress.txt (last entry) for handoff notes on what was done and what remains.
Pick up from where they left off — do NOT restart the story from scratch.
```

### Case C: Active sprint with incomplete stories (normal continuation)

No uncommitted changes, no WIP — the last agent finished cleanly and there's more work to do. If the current branch doesn't match `prd.json.branchName`, check out the correct branch first.

Show the sprint dashboard:
```
## Active Sprint: [description]

Branch: [branchName]

| # | Story | Status |
|---|-------|--------|
...

Progress: [completed]/[total] stories
Next up: [first story where passes: false]
```

**If there are newly completed stories that haven't been reviewed yet** (check git log for recent `feat:` commits), offer to review before continuing:

Ask the user: "There are completed stories since the last review. Would you like to review them first, or start on [next STORY-ID]?"
- **Review first** — launch the `story-reviewer` subagent, show results, then ask to continue
- **Start on the next story** — proceed directly

Once the user is ready to continue, proceed to **Start Working**.

### Case D: All stories complete, branch not merged

Every story has `passes: true` but we're still on the Ralph branch (not main).

Show:
```
## Sprint Complete! Ready to Review & Merge

Sprint: [description]
Branch: [branchName]
Stories completed: [total]
```

**Before merging, run the story reviewer.** Use the Task tool to launch the `story-reviewer` agent to review all completed stories on the branch. Show the results to the user.

**Also check tech debt.** If the tech debt file (from RALPH.md Documents.tech_debt) exists, read it and show the active item count and any high-severity items. Use the `tech-debt-review` skill if available.

Then ask: "What would you like to do?"
- **Merge to main and start next sprint** — merge the branch, push, then run `/new-sprint` which auto-detects the next feature from the PRD
- **Merge to main** — just merge, don't start a new sprint yet
- **Fix issues first** — proceed to **Start Working** with review findings as extra context

If the user chooses "Merge and start next sprint":
1. `git checkout main && git merge [branchName]`
2. `git push origin main`
3. **If prd.json has `"source": "backlog"`**: Update the corresponding item's status in the backlog file (from RALPH.md Documents.backlog) to `**Status:** Complete ([date])`. Use the `sourceItem` number to find the right section.
4. **Versioning**: If your project uses versioning, bump version and tag per your conventions. Show the user: "Does your project use versioning? If so, bump the version now (e.g., update version files, changelog, create a git tag) before we continue."
5. Tell the user: "Sprint merged! Now let's set up the next one."
6. Follow the `/new-sprint` skill instructions from Step 1 (it will auto-detect the next feature from the PRD or backlog)

### Case E: On main, no active sprint

Either prd.json doesn't exist, or all stories are done and the branch was already merged.

Show:
```
## No Active Sprint

Last completed: [description from prd.json if it exists, or "none"]
```

Then ask: "Ready to start the next sprint? `/new-sprint` will check the PRD and backlog for the next piece of work."
- **Yes, start next sprint** — follow the `/new-sprint` skill instructions from Step 1
- **Not now** — end the session

### Case F: Active test plan in progress

The test plan file (from RALPH.md Testing.test_plan) exists and has test cases where `passes` is `null` (not yet tested) or `false` (failed, may need re-test).

**If BOTH an active sprint AND an active test plan exist**, show both and ask which to work on.

Show:
```
## Active Test Plan

Test Plan: [name]
Device: [device]
Progress: [passed]/[total] passed, [failed] failed, [remaining] remaining
Open Issues: [count from issues file if it exists]
```

Read the test progress file from RALPH.md Testing.test_progress (last entry) to see what was done last session.

Ask: "You have an active test plan. What would you like to do?"
- **Continue testing** — invoke the `/test` skill to resume the testing loop
- **Review/fix open issues** — read the issues file, work through logged issues
- **Something else** — proceed to other cases

### Case G: Unexpected state

If the state doesn't clearly match any case above (e.g., on an unrelated branch, prd.json is corrupted, etc.), show:
```
## Current State

Branch: [branch]
Git status: [summary]
PRD: [summary or "not found"]
```

And offer options:
- **Switch to main** — `git checkout main`, then re-assess
- **Re-run /init** — reinitialize the project configuration
- **Describe what you'd like to do** — let the user explain their intent

---

## Start Working

Once the user confirms they're ready, you become the worker agent for this session.

### Load Context (silently)

Read these files — don't dump contents to the user:

1. `scripts/ralph/prompt.md` — the Ralph agent instructions
2. `scripts/ralph/prd.json` — current sprint and user stories
3. `scripts/ralph/progress.txt` — the "Codebase Patterns" section at the top
4. `RALPH.md` — project config, quality commands, document paths
5. `CLAUDE.md` — project overview, commands, tech stack, key patterns (if exists)
6. `AGENTS.md` — codebase conventions, key files, gotchas (if exists)
7. The design doc configured in RALPH.md Documents.design (if configured) — UI/UX guidelines
8. The tech debt file from RALPH.md Documents.tech_debt — silently note any active high-severity items that could affect the current story (if exists)

### Execute the Ralph Loop

Follow `prompt.md` directly — you ARE the worker agent now:

1. Check you're on the correct branch from PRD `branchName`. If not, check it out or create from main.
2. Pick the highest priority story where `passes: false` (or continue the interrupted story if Case B).
3. **Explore relevant code** before implementing (see the Codebase Exploration section in prompt.md — this is NOT optional).
4. Implement that single story.
5. Run quality checks — execute every non-empty command from RALPH.md Quality Commands (typecheck, lint, test). If the story has a `testFlow` and RALPH.md has `e2e_single` configured, run the E2E command with the flow path.
6. If all checks pass, commit with: `feat: [Story ID] - [Story Title]`
7. Update prd.json to set `passes: true` for the completed story.
8. Append progress to `progress.txt`.
9. After completing the story, stop and show the results. Ask the user if they want to continue with the next story or wrap up.
