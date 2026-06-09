---
name: start
description: Assess project state and pick up where the last session left off — the single entry point for any new session
disable-model-invocation: true
---

# /start — Project State Dispatcher

This is the first thing to run in any new session. It reads the project state, shows what's going on, and picks up where the last session left off.

## Step 1: Gather State (silently)

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
Stop here.

**Once RALPH.md is validated**, read all paths from it. Capture these settings (use the defaults when sections are missing — back-compat with v1 RALPH.md):

- `Audit.mode` — `off | sprint-close | per-story` (default: `sprint-close`)
- `Audit.reports_dir` — default `scripts/ralph/audit-reports`
- `Merge.mode` — `local | pr` (default: `local`)
- `Merge.branch_base` — default `main`
- `Github.enabled` — `true | false` (default: `false`)

Then gather state:

1. Run `git status` — check for uncommitted changes, current branch
2. Run `git log --oneline -5` — see recent commits (look for `wip:` commits from interrupted sessions)
3. Read `scripts/ralph/prd.json` — current sprint, which stories pass/fail
4. Read the test plan file from RALPH.md Testing.test_plan (if configured) — active test plan, if any
5. Read `scripts/ralph/progress.txt` — only the last entry (scroll to bottom) to see what was last done
6. Read the issues file from RALPH.md Documents.issues — check for bugs with status `Logged` (not yet fixed)
7. Read the backlog file from RALPH.md Documents.backlog — check for recent quick-capture entries (status: `Idea — quick capture`)
8. **If `Github.enabled` is true**, run `gh issue list --state open --json number,title,labels,createdAt --limit 50` — check for open GitHub Issues. If `gh` is not installed or auth fails, fall back gracefully (skip this step and warn the user once).

## Step 2: Determine Situation & Act

Based on what you found, follow the FIRST matching case.

**Logged Items / Open Issues Check** — regardless of which case matches, append after the case-specific dashboard:

```
### Logged Items
- [N] open bug(s) in [issues file path]
- [N] improvement idea(s) in [backlog file path]
```

If `Github.enabled` and there are open GitHub Issues:

```
### Open GitHub Issues ([N] total)
| # | Title | Type | Priority | Created |
|---|-------|------|----------|---------|
| #[number] | [title] | [bug/enhancement/tech-debt] | [P0/P1/P2 from labels] | [relative date] |

Breakdown: [N] bug(s), [N] enhancement(s), [N] tech-debt
```

Only show these sections if items exist. Sort by priority (P0 first), then type.

If P0/critical items exist, flag them:
```
⚠️ [N] critical issue(s) need attention.
```

The user can choose to:
- **Pick an issue/item to work on** — tell the lead to implement the fix (proceed to Start Working with the issue as context)
- **Ignore for now** — continue with the normal sprint flow
- **Close stale issues** — if any have already been addressed

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
Last agent was working on: [story ID]
WIP commit: [commit message]

| # | Story | Status |
|---|-------|--------|
...

Progress: [completed]/[total] stories
```

Read the last progress.txt entry and show a brief summary of the handoff notes.

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

**If `Audit.mode = per-story` and there are recently completed stories that haven't been signed off yet** (check git log for recent `feat:` commits without corresponding `chore(ralph): ... mark passes` commits), offer to audit them before continuing.

Otherwise proceed to **Start Working**.

### Case D: All stories complete, branch not merged

Every story has `passes: true` but we're still on the Ralph branch (not `<Merge.branch_base>`).

Show:
```
## Sprint Complete! Ready to Review & Merge

Sprint: [description]
Branch: [branchName]
Stories completed: [total]
```

> **Team name (`<team>`):** resolve once per session — `team_name` from RALPH.md's `## Audit` section if set, otherwise `ralph-<project-folder>` (the kebab-cased basename of the repo root, e.g. `ralph-closetize-website`). Never use the bare name `ralph`: teams are machine-global (`~/.claude/teams/`), shared across every terminal and directory, so a fixed literal name cross-wires concurrent Ralph projects — a lead in one repo can wake an idle session in another repo and send it work.

**Sprint-close audit:**

- If `Audit.mode = off` — skip the audit.
- If `Audit.mode = sprint-close` or `per-story` — run the sprint-close branch sweep:
  ```
  Agent({ subagent_type: "auditor", team_name: "<team>", name: "auditor", description: "Ralph sprint auditor",
          prompt: "Run setup per agents/auditor.md, then audit branch sprint-close. Write to <Audit.reports_dir>/BRANCH-AUDIT-<branch-name>.md. SendMessage the verdict back." })
  ```
  Wait for the verdict, then show it to the user.

**Also check tech debt.** If the tech debt file (from RALPH.md Documents.tech_debt) exists, read it and show the active item count and any high-severity items. Use the `tech-debt-review` skill if available.

If the auditor found critical issues, ask the user to fix them first (proceed to **Start Working** with findings as context).

If no critical issues (or user chooses to proceed), branch to the merge flow based on `Merge.mode`:

#### Merge.mode = local (default)

```
1. git checkout <Merge.branch_base>
2. git merge [branchName]
3. git push origin <Merge.branch_base>
4. If prd.json has "source": "backlog" with sourceItem — update the corresponding item's status in the backlog file to `**Status:** Complete ([date])`.
5. If prd.json has "source": "github-issue" with sourceIssues — verify auto-close via `Fixes #N` keywords in commits. For any that didn't auto-close, run `gh issue close [NUMBER] --comment "Resolved in [branchName]."`.
6. Versioning: ask the user if the project uses versioning. If yes, bump version files + CHANGELOG, create a git tag.
7. Tell the user: "Sprint merged! Run /new-sprint to set up the next one."
```

#### Merge.mode = pr

Open a PR for external review. The plugin does NOT ship a reviewer dispatch script — that's project-specific (you may use manual review, CI, your own Claude Code agent dispatch, etc.).

```
1. git push -u origin [branchName]
2. gh pr create --base <Merge.branch_base> --head [branchName] \
     --title "feat: [description from prd.json]" \
     --body "<sprint summary with story list and source issues>"
3. Show the PR URL.
4. Tell the user: "PR opened. Dispatch your reviewers now (whatever your project uses). When the PR is approved, run /start again — Case D2 will pick it up and merge."
```

Then **stop** — don't merge locally. The PR is the review gate.

### Case D2: Open PR exists, awaiting review or changes requested (Merge.mode = pr only)

If a PR already exists for the current branch (check with `gh pr view [branchName] --json state,reviews,comments`):

- **If reviews are pending** — remind the user that reviewers haven't posted yet. Ask if they want to dispatch reviewers (project-specific — surface as "run your reviewer command").
- **If changes were requested** — pull review comments with `gh pr view --comments`, summarize the requested changes, ask if the user wants to fix them. If yes, proceed to **Start Working** with the review feedback as context. After fixes, commit, push.
- **If approved** — proceed to merge:
  ```
  1. gh pr merge [PR_NUMBER] --merge
  2. git checkout <Merge.branch_base> && git pull origin <Merge.branch_base>
  3. If versioning: tag the merge commit (git tag vX.Y.Z && git push origin vX.Y.Z).
  4. Close source issues (verify auto-close, then manually close any that didn't).
  5. Tell the user: "PR merged! Run /new-sprint to set up the next one."
  ```

### Case E: On the base branch, no active sprint

Either prd.json doesn't exist, or all stories are done and the branch was already merged.

Show:
```
## No Active Sprint

Last completed: [description from prd.json if it exists, or "none"]
```

Then ask: "Ready to start the next sprint? `/new-sprint` will check the PRD and backlog for the next piece of work."
- **Yes, start next sprint** — follow the `/new-sprint` skill from Step 1
- **Not now** — end the session

### Case F: Active test plan in progress

The test plan file (from RALPH.md Testing.test_plan) exists and has test cases where `passes` is `null` or `false`.

**If BOTH an active sprint AND an active test plan exist**, show both and ask which to work on.

Show:
```
## Active Test Plan

Test Plan: [name]
Device: [device]
Progress: [passed]/[total] passed, [failed] failed, [remaining] remaining
Open Issues: [count from issues file if it exists]
```

Read the test progress file (last entry) to see what was done last session.

Ask: "You have an active test plan. What would you like to do?"
- **Continue testing** — invoke the `/test` skill
- **Review/fix open issues** — read the issues file, work through logged issues
- **Something else** — proceed to other cases

### Case G: Unexpected state

If the state doesn't clearly match any case above (on an unrelated branch, prd.json is corrupted, etc.), show:
```
## Current State

Branch: [branch]
Git status: [summary]
PRD: [summary or "not found"]
```

Offer:
- **Switch to base branch** — `git checkout <Merge.branch_base>`, then re-assess
- **Re-run /ralph-init** — reinitialize configuration
- **Describe what you'd like to do** — let the user explain their intent

---

## Start Working

Once the user confirms they're ready, you become the worker agent for this session.

### Load Context (silently)

Read these files — don't dump contents:

1. `scripts/ralph/prompt.md` — the Ralph agent instructions
2. `scripts/ralph/prd.json` — current sprint and user stories
3. `scripts/ralph/progress.txt` — the "Codebase Patterns" section at the top
4. `RALPH.md` — project config (already validated)
5. `CLAUDE.md` — project overview, commands, tech stack, key patterns (if exists)
6. `AGENTS.md` — codebase conventions, key files, gotchas (if exists)
7. The design doc configured in RALPH.md Documents.design (if configured)
8. The tech debt file from RALPH.md Documents.tech_debt (if exists) — silently note high-severity items that could affect the current story

### Execute the Ralph Loop

Follow `prompt.md` directly — you ARE the worker agent now:

1. Check you're on the correct branch from PRD `branchName`. If not, check it out or create from `<Merge.branch_base>`.
2. **If `Audit.mode = per-story`**: spawn (or revive) the auditor teammate — see "Audit Gate" below. Do this BEFORE picking the first story so the auditor is ready when the first `feat:` commit lands.
3. Pick the highest priority story where `passes: false` (or continue the interrupted story if Case B).
   - **If the user chose to work on a GitHub Issue instead of a PRD story** (when Github.enabled): read the full issue with `gh issue view [NUMBER]`, use it as the task specification, and include `Fixes #[NUMBER]` in the commit message body.
4. **Explore relevant code** before implementing (see the Codebase Exploration section in prompt.md).
5. Implement that single story.
6. Run quality checks (every non-empty command from RALPH.md Quality Commands; plus E2E if the story has a `testFlow` and `e2e_single` is configured).
7. If all checks pass, commit with `feat: [Story ID] - [Story Title]` (or `fix: [brief description] — Fixes #[ISSUE_NUMBER]` for GitHub Issue work).
8. **Audit Gate** — branch by `Audit.mode`:
   - `off` — flip `passes: true` in `prd.json` yourself; update progress.txt; move on.
   - `sprint-close` — flip `passes: true` yourself; update progress.txt; move on. The branch-level audit runs in Case D.
   - `per-story` — see "Audit Gate" below. SendMessage the auditor with the story ID + commit SHA. Wait for the verdict. Apply auto-flip + humanGated logic. If FAIL, fix and re-message; cap at 3 iterations.
9. After the verdict is resolved (or skipped for off/sprint-close), append progress to `progress.txt`.
10. **Context-discipline check** before picking up the next story — a **live, in-process decision**. After progress is logged, run `/ctx` to read the actual current context %, then:
    - **< 40%** → proceed to the next story.
    - **40–60%** → do NOT start a new story. Prompt the user: "Context at X% — recommend `/wrap` before the next story. Continue / wrap / status?" Respect their override.
    - **≥ 60%** → strongly recommend `/wrap` now; do NOT start a new story. Clean session exit (lead + auditor wrap together via `/wrap` — see /wrap skill).
    - Judgment: if you're near 40% and the next story is large, prefer wrapping first.
11. After completing the story (assuming no wrap triggered), continue the loop from step 3.

**Why context discipline matters:** Quality degrades with context utilization well before the model "fails" — degradation tracks absolute token count. Auto-compaction is lossy, so we `/wrap` (clean handoff) *before* it. The wrap decision is made **live via `/ctx`** at the thresholds above. Between stories the loop runs autonomously (no user prompt), so the global UserPromptSubmit hook won't fire — you must **actively run `/ctx`** to read the %.

### Audit Gate (Audit.mode = per-story)

The auditor agent (`agents/auditor.md`) runs as a long-lived teammate. The lead messages it after each `feat:` commit; it reads the diff, runs static gates, performs hands-on verifications, writes a report to `<Audit.reports_dir>/R-<STORY-ID>.md`, and SendMessages back its verdict.

**Spawning the auditor (first story of session):**

Check if the team already exists at `~/.claude/teams/<team>/config.json`. If yes, the team is alive — verify the auditor is a member; if so, skip ahead to "subsequent stories." If the team file doesn't exist, create it:

```
TeamCreate({
  team_name: "<team>",
  agent_type: "team-lead",
  description: "Ralph sprint coordination — lead + auditor"
})
```

Then spawn the auditor:

```
Agent({
  subagent_type: "auditor",
  team_name: "<team>",
  name: "auditor",
  description: "Ralph sprint auditor",
  prompt: "You are joining the '<team>' team as the auditor. Run setup per agents/auditor.md (read RALPH.md, PRD, PATTERNS.md, audit-progress.txt last entry, progress.txt last entry, git state). Then go idle and wait for an audit task message from team-lead."
})
```

If `audit-progress.txt` shows a prior session's wrap state, the auditor's setup flow picks that up automatically.

**Per-story audit message (after each feat: commit):**

```
SendMessage({
  to: "auditor",
  summary: "audit story <STORY-ID>",
  message: "audit story <STORY-ID>, commit <SHA>. Follow your per-story flow exactly. SendMessage the verdict + report path back when done."
})
```

Then **wait for the auditor's reply** — it auto-delivers as a new conversation turn.

**Verdict handling:**

| Auditor verdict | Lead's action |
|---|---|
| `SIGN OFF` | Read the report at `R-<STORY-ID>.md`. Create `chore(ralph): <STORY-ID> - mark passes after audit sign-off` commit that flips `passes: true` in `prd.json`. Append AC scorecard + evidence to `progress.txt`. Move to next story (after context-discipline check). |
| `PASS-PENDING-HUMAN` | Story stays `passes: false`. Surface the exact humanGated AC text to the user: "AC #X needs your verification: <text>". May continue with the next story IF it doesn't depend on this one. When the human confirms, send `SendMessage({ to: "auditor", message: "human confirmed AC #X for story <ID>" })` — auditor flips verdict to PASS, lead does the chore commit. |
| `REQUEST CHANGES` / `FAIL` | Read the report. Apply fixes. Commit as `fix(ralph): <STORY-ID> - <summary>`. SendMessage the auditor again with the new commit SHA. **Cap re-audit at 3 iterations.** After the 3rd FAIL, stop and ask the user: "Auditor and coder disagree on story <ID> after 3 attempts. Here's both perspectives: [report excerpts]. What's right?" |
| `BLOCK` | Stop the loop. Surface the issue to the user with the report path. Don't auto-resume. |

**Subsequent stories in the same sprint:** the auditor is already alive and idle — just SendMessage the per-story audit task. No re-spawn needed.

**At sprint merge:** team config persists across sprints by design — do not tear down. The next sprint reuses the same `<team>` team; `/start` checks for the existing config and re-spawns the auditor as a member if needed. Mid-sprint `/wrap` explicitly preserves the team for resume. `TeamDelete` is for recovery scenarios only (corrupted config, stale roster after a crash) — never run it as part of normal sprint close.
