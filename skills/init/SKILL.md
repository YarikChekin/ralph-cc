---
name: init
description: Scaffold ralph-cc into a project — creates RALPH.md config, scripts/ralph/ directory, and doc templates. Run this once to set up ralph in any project.
---

# /init — Scaffold Ralph into a Project

You are the ralph-cc initialization skill. Your job is to scaffold the ralph workflow into the current project by creating template files and writing a RALPH.md configuration.

Follow these steps in order. Ask one question at a time. Do not skip steps.

---

## Step 1: Check for Existing Setup

Check if `RALPH.md` exists in the project root.

**If RALPH.md exists:**
- Read it and display the current configuration to the user in a readable format
- Ask: "Ralph is already initialized in this project. Would you like to **reconfigure** (re-run setup) or **abort**?"
- If abort: stop here, show the existing config, and suggest `/start` to begin working
- If reconfigure: proceed to Step 2 (existing files will be preserved, only RALPH.md will be rewritten)

**If RALPH.md does not exist:**
- Say: "No RALPH.md found — let's set up ralph in this project."
- Proceed to Step 2

---

## Step 2: Scaffold Directory Structure

Create the following files and directories. Use `mkdir -p` to create directories. For each file, only create it if it does NOT already exist — never overwrite existing project files (except RALPH.md during reconfigure).

### scripts/ralph/prompt.md

Copy the ralph agent instructions. This is the core execution loop that the Ralph agent follows when working on stories. Write the following content:

```markdown
# Ralph Agent Instructions

You are an autonomous coding agent working on a software project.

## Your Task

1. Read RALPH.md to understand project config, quality commands, and document paths
2. Read the PRD at `prd.json` (in the same directory as this file)
3. Read the progress log at `progress.txt` (check Codebase Patterns section first)
4. Check you're on the correct branch from PRD `branchName`. If not, check it out or create from main.
5. Pick the **highest priority** user story where `passes: false`
6. **Explore relevant code** before implementing (see Codebase Exploration below)
7. Implement that single user story
8. Run quality checks (see Quality Requirements below)
9. If the story has a `testFlow` and RALPH.md has `e2e_single` configured, run the E2E command with the flow path
10. Update AGENTS.md files if you discover reusable patterns (see below)
11. If all checks pass, commit ALL changes with message: `feat: [Story ID] - [Story Title]`
12. Update the PRD to set `passes: true` for the completed story
13. Append your progress to `progress.txt`

## Git Commit Rules

- Commit message format: `feat: [Story ID] - [Story Title]`
- Do NOT include any co-author tags or AI attribution in commits
- Keep commits atomic and focused on the story

## Codebase Exploration

After picking a story and before writing any code, explore the existing codebase to understand the patterns and implementations you'll be building on. This prevents reinventing things and ensures consistency.

**For every story, read:**
1. **The closest completed feature** — find the most recently implemented screen or component in the same area (e.g., if building a new screen, read the last completed screen in that module). This is your reference implementation.
2. **Shared components you'll use** — check for reusable components (UI elements, utilities, etc.) that you should extend or reuse rather than rebuild.
3. **Context/hooks you'll interact with** — read the context providers, hooks, and services relevant to your story.
4. **The database schema** — check the migrations or schema files to understand the exact column names, types, and constraints for tables you'll interact with.

**How to find relevant files:**
- Look at `progress.txt` entries for recently completed stories — they list all files changed
- Check `prd.json` for completed stories in the same feature area
- Search the project for existing utilities, components, and helpers

**The goal is to understand:**
- What UI patterns and component APIs are already established
- What styling conventions are used
- How data flows through the application (API calls, state management, persistence)
- What naming conventions and file organization patterns are in place

Do NOT skip this step. Reading 5-10 files before coding saves time and produces more consistent results.

## Progress Report Format

**IMPORTANT: progress.txt is a living document.**
- NEVER delete or replace content - only append
- All history from previous features stays in the file
- The Codebase Patterns section grows over time as new patterns are discovered
- When starting a new feature, add a feature header and continue appending

APPEND to progress.txt (never replace, always append):
```
## [Date] - [Story ID]
- What was implemented
- Files changed
- **Learnings for future iterations:**
  - Patterns discovered (e.g., "this codebase uses X for Y")
  - Gotchas encountered (e.g., "don't forget to update Z when changing W")
  - Useful context (e.g., "the evaluation panel is in component X")
---
```

The learnings section is critical - it helps future iterations avoid repeating mistakes and understand the codebase better.

## Consolidate Patterns

If you discover a **reusable pattern** that future iterations should know, add it to the `## Codebase Patterns` section at the TOP of progress.txt (create it if it doesn't exist). This section should consolidate the most important learnings:

```
## Codebase Patterns
- Example: Use `sql<number>` template for aggregations
- Example: Always use `IF NOT EXISTS` for migrations
- Example: Export types from actions.ts for UI components
```

Only add patterns that are **general and reusable**, not story-specific details.

## Update AGENTS.md Files

Before committing, check if any edited files have learnings worth preserving in nearby AGENTS.md files:

1. **Identify directories with edited files** - Look at which directories you modified
2. **Check for existing AGENTS.md** - Look for AGENTS.md in those directories or parent directories
3. **Add valuable learnings** - If you discovered something future developers/agents should know:
   - API patterns or conventions specific to that module
   - Gotchas or non-obvious requirements
   - Dependencies between files
   - Testing approaches for that area
   - Configuration or environment requirements

**Examples of good AGENTS.md additions:**
- "When modifying X, also update Y to keep them in sync"
- "This module uses pattern Z for all API calls"
- "Tests require the dev server running on PORT 3000"
- "Field names must match the template exactly"

**Do NOT add:**
- Story-specific implementation details
- Temporary debugging notes
- Information already in progress.txt

Only update AGENTS.md if you have **genuinely reusable knowledge** that would help future work in that directory.

## Quality Requirements

Run the quality commands defined in RALPH.md before committing. At minimum:

1. **Typecheck** — Run the typecheck command from RALPH.md. Must pass with no errors.
2. **Lint** — Run the lint command from RALPH.md. Must pass with no violations.
3. **Tests** — Run the test command from RALPH.md (if configured). Must pass.
4. **E2E** — If the story has a `testFlow` and RALPH.md has `e2e_single` configured, run the E2E command with the flow path. Must pass.

Do NOT commit broken code. Keep changes focused and minimal. Follow existing code patterns.

## E2E Testing

For stories with UI changes, a `testFlow` field may specify the test file path:

```json
{
  "id": "AUTH-001",
  "title": "Create login screen",
  "testFlow": "e2e/auth/login.test.ts",
  ...
}
```

**If the flow file does not exist yet, you must create it.** Check for E2E test reference docs in the project (look for AGENTS.md or README files in the test directory) — they contain the required setup, patterns, and gotchas for writing tests. Key rules:

- Follow the existing E2E test patterns in the project
- Read any test configuration files and reference docs before writing tests
- Use the same setup/teardown patterns as existing tests
- Create the feature test directory if it doesn't exist

**Before marking the story complete:**
1. Run the E2E command from RALPH.md with the `testFlow` path
2. If the test fails, fix the issue and re-run until it passes
3. Check failure logs/screenshots if the test runner provides them

**If no `testFlow` is specified**, the story does not require E2E testing.

## Tech Debt

**Default: fix issues as you find them.** Only defer to the tech debt file (configured in RALPH.md) when ALL of these are true:

1. The issue is **not caused by the current story** (it's pre-existing or cross-cutting)
2. Fixing it would require **changes to unrelated files or features**
3. The issue does **not affect the current story's UX or correctness**

If any of those conditions are false, fix it now as part of the current story.

**When deferring**, add an entry to the tech debt file under "Active Items" with:
- **ID:** TD-NNN (next sequential number)
- **Origin:** story ID that discovered it
- **Severity:** High / Medium / Low
- **Effort:** Trivial / Small / Medium / Large
- **Description:** what's wrong and why it matters
- **Files:** affected file paths

**When fixing a tech debt item** (either as part of a story or standalone), update the tech debt file:
1. Move the item from "Active Items" to "Resolved Items"
2. Add a **Resolution:** line summarizing what was done and why the approach was chosen
3. Keep the original severity/effort/description for audit trail

**Never defer:** data bugs, broken user flows, stale state, security issues. These get fixed immediately regardless of scope.

## Stop Condition

After completing a user story, check if ALL stories have `passes: true`.

**If there are still stories with `passes: false`:**
End your response normally. Another iteration will pick up the next story.

**If ALL stories are complete and passing:**
Reply with a completion summary:

```
---
## FEATURE COMPLETE

All user stories in this prd.json have been implemented and are passing.

**Feature:** [Feature name from prd.json description]
**Branch:** [branchName from prd.json]
**Stories completed:** [count]

### Recommended Next Steps:
1. Review the changes on this branch
2. Merge to main when ready: `git checkout main && git merge [branchName]`
3. Archive prd.json: `cp scripts/ralph/prd.json scripts/ralph/archive/[feature]-prd.json`
4. Create the next prd.json for the next feature
5. Do NOT reset progress.txt - it's a living document that preserves all learnings

<promise>COMPLETE</promise>
---
```

## Important

- Work on ONE story per iteration
- Commit frequently
- Keep quality checks green
- Read the Codebase Patterns section in progress.txt before starting
- Consult the design doc configured in RALPH.md (if any) for UI/UX guidelines
- Do NOT add AI co-author attribution to commits
```

### scripts/ralph/prd.json.example

Copy the example sprint format so users have a reference. Write the following content:

```json
{
  "project": "MyApp",
  "source": "prd",
  "sourceItem": "3.1",
  "branchName": "ralph/user-auth",
  "description": "User Authentication — signup, login, session management",
  "userStories": [
    {
      "id": "AUTH-001",
      "title": "Add users table and auth schema",
      "description": "Set up the database schema for user authentication.",
      "acceptanceCriteria": [
        "Create users table with email, password_hash, created_at columns",
        "Add migration file",
        "Typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "testFlow": null,
      "notes": "Follow existing migration patterns in the project."
    },
    {
      "id": "AUTH-002",
      "title": "Create login screen with form validation",
      "description": "Build the login UI with email/password fields and client-side validation.",
      "acceptanceCriteria": [
        "Login form with email and password fields",
        "Client-side validation (email format, password length)",
        "Error messages for invalid input",
        "Typecheck passes"
      ],
      "priority": 2,
      "passes": false,
      "testFlow": null,
      "notes": "Follow existing form patterns in the codebase."
    }
  ]
}
```

### scripts/ralph/progress.txt

Create with the initial structure. Use today's date:

```
# Ralph Progress Log
Started: [today's date]

## Codebase Patterns
(Discovered patterns are consolidated here — always read this section first)

---
```

Replace `[today's date]` with the actual current date.

### docs/tech-debt.md

Only create if it does NOT already exist. Write the following content:

```markdown
# Tech Debt

## Active Items

| ID | Origin | Severity | Effort | Description | Files |
|----|--------|----------|--------|-------------|-------|

## Resolved Items

| ID | Origin | Severity | Effort | Description | Resolution |
|----|--------|----------|--------|-------------|------------|
```

### docs/testing/issues.md

Only create if it does NOT already exist. Write the following content:

```markdown
# Testing Issues

| # | Severity | Feature | Description | Status |
|---|----------|---------|-------------|--------|

## Severity Levels
- **Blocker**: Can't continue testing or core feature broken
- **Major**: Feature broken, workaround exists. Fix before launch.
- **Minor**: Cosmetic or UX. Fix when convenient.
- **Polish**: Nice-to-have improvement. Backlog.

## Status Values
- **Logged**: Found, not yet addressed
- **Fixed**: Fixed and verified (include commit hash)
- **Deferred**: Intentionally postponed (include reason)
- **Won't Fix**: Decided not to fix (include reason)
```

### docs/ideas/_index.md

Only create if it does NOT already exist. Write the following content:

```markdown
# Ideas

Living index of product ideas. Use `/new-idea` to add new entries.

| Idea | Status | Effort | Value | File |
|------|--------|--------|-------|------|
```

**After scaffolding, tell the user what was created (list each file) and what was skipped (already existed).**

---

## Step 3: Ask Setup Questions

Before asking, scan the project for hints. Check these files if they exist:
- `package.json` — look for scripts (typecheck, lint, test, e2e)
- `Makefile` — look for targets (typecheck, lint, test)
- `pyproject.toml` — look for tool configurations (ruff, mypy, pytest)
- `Cargo.toml` — look for Rust project info
- `go.mod` — look for Go module info
- `composer.json` — look for PHP project info
- `.github/workflows/*.yml` — look for CI commands

Use detected hints as smart defaults. Ask questions one at a time. Wait for the user's answer before asking the next question.

### Question 1
"What's your project name?"

Use the current directory name as the default suggestion. For example: "What's your project name? (default: **my-app**)"

### Question 2
"One-line description of what you're building?"

### Question 3
"Is this a new product or a feature for an existing project?" (product | feature)

### Question 4
"What's your typecheck command?"

If you detected a hint, show it. For example:
- "Detected `tsc` in package.json scripts — use `npm run typecheck`?"
- "Detected `mypy` in pyproject.toml — use `mypy .`?"
- If no hint found: "What's your typecheck command? (e.g., `npm run typecheck`, `mypy .`, leave blank if none)"

### Question 5
"What's your lint command?"

Show detected hint if found. For example:
- "Detected `eslint` in package.json scripts — use `npm run lint`?"
- "Detected `ruff` in pyproject.toml — use `ruff check .`?"

### Question 6
"What's your test command?"

Show detected hint if found. For example:
- "Detected `jest` in package.json scripts — use `npm test`?"
- "Detected `pytest` in pyproject.toml — use `pytest`?"

### Question 7
"Do you have an E2E test setup? If so, what's the command to run all E2E tests?"

This is optional. If the user says no or skips, leave the e2e fields blank in RALPH.md.

Show detected hint if found (e.g., "Detected `playwright` in devDependencies — use `npx playwright test`?")

### Question 8 (only if E2E was provided)
"What's the command to run a single E2E test file? Use `{flow}` as placeholder for the test path."

For example: `npx playwright test {flow}`, `bash scripts/test-e2e.sh {flow}`

---

## Step 4: Write RALPH.md

Write `RALPH.md` to the project root using the collected answers. Use this format exactly:

```markdown
# RALPH.md

## Project
Name: [project name]
Description: [description]
Type: [product | feature]

## Quality Commands
typecheck: [typecheck command or blank]
lint: [lint command or blank]
test: [test command or blank]
e2e: [e2e command or blank if not provided]
e2e_single: [e2e single command or blank if not provided]

## Documents
prd: docs/PRD.md
backlog: docs/POST_MVP_IMPROVEMENTS.md
design:
tech_debt: docs/tech-debt.md
issues: docs/testing/issues.md
ideas: docs/ideas/_index.md

## Testing (optional — only if using /test for manual testing)
test_plan: scripts/ralph/test-plan.json
test_progress: scripts/ralph/test-progress.txt

## Git
commit_format: feat: [{story_id}] - [{title}]
branch_prefix: ralph/
```

Leave optional fields blank (just the key with no value) if the user didn't provide them.

---

## Step 5: Update CLAUDE.md (if exists)

Check if `CLAUDE.md` exists in the project root.

**If it exists**, read it and check if it already has a "Ralph Workflow" section. If it does NOT already have one, append the following to the end of the file:

```markdown

## Ralph Workflow

This project uses ralph-cc for structured development. See `RALPH.md` for project configuration.

Key commands:
- `/start` — Begin a session (picks up where you left off)
- `/new-sprint` — Generate the next sprint from the PRD
- `/wrap` — End a session cleanly
- `/ralph` — Quick sprint status check

See the ralph-cc README for the full skill reference.
```

**If CLAUDE.md does not exist**, skip this step. Do not create a CLAUDE.md.

---

## Step 6: Show Next Steps

After everything is written, display this summary:

```
Ralph initialized!

Created:
  RALPH.md              — project configuration
  scripts/ralph/        — agent instructions and sprint data
  docs/tech-debt.md     — tech debt tracking
  docs/testing/issues.md — bug tracking
  docs/ideas/_index.md  — idea capture

Next steps:
  1. Run /prd-plan to define your product requirements
  2. Run /new-sprint to create your first sprint
  3. Run /start to begin working
```

Adjust the "Created" list to reflect what was actually created vs skipped. If a file already existed and was not overwritten, note it as "already exists — skipped".

---

## Important Notes

- **E2E testing is always optional.** It only applies if configured in RALPH.md (the `e2e` and `e2e_single` fields). If not configured, all skills skip E2E references entirely — no `testFlow` field in stories, no E2E step in quality checks.
- **Never overwrite existing project files** (docs/tech-debt.md, docs/testing/issues.md, docs/ideas/_index.md) — only create them if they don't exist. RALPH.md is the exception during reconfigure.
- **This skill does NOT create a PRD.** That is `/prd-plan`'s job. `/init` saves the project name and type to RALPH.md, which `/prd-plan` reads to avoid re-asking.
- **Do NOT add AI co-author attribution to any commits.**
