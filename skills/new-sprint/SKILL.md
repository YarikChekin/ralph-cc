---
name: new-sprint
description: Generate the next sprint from the PRD, backlog, or tech debt — detects completed features, picks the next chunk of work, and builds user stories with minimal user input
---

# /new-sprint — Generate Next Sprint

Creates a new `scripts/ralph/prd.json` by reading the PRD, backlog, and tech debt, detecting what's already been built. The user should only need to confirm or tweak — not describe features from scratch.

## Gate

Before anything else, check that `RALPH.md` exists in the project root and has `Documents.prd` defined with a non-empty path.

- **If RALPH.md is missing:** Stop immediately. Tell the user:
  > "No RALPH.md found. Run `/init` to set up ralph in this project."
- **If Documents.prd is missing or empty:** Stop immediately. Tell the user:
  > "No PRD found. Run `/prd-plan` to create one."
- **If the PRD file itself doesn't exist at the configured path:** Stop immediately. Tell the user:
  > "PRD file not found at `[path]`. Run `/prd-plan` to create one, or update the path in RALPH.md."

Once validated, read all paths from RALPH.md and proceed.

---

## Step 1: Detect What's Been Built

Silently read all of these:

1. **PRD** (from RALPH.md Documents.prd) — the full product requirements document
2. **Backlog** (from RALPH.md Documents.backlog, if exists) — planned improvements with Status fields
3. **Tech debt** (from RALPH.md Documents.tech_debt, if exists) — tracked tech debt items with severity and effort
4. **Ideas** (from RALPH.md Documents.ideas, if exists) — idea backlog
5. **Archived sprints** — list all directories in `scripts/ralph/archive/` to see completed features
6. `scripts/ralph/prd.json` — current sprint (may be complete or in-progress)
7. `scripts/ralph/progress.txt` — the "Codebase Patterns" section at the top for implementation context
8. `CLAUDE.md` — tech stack, project structure, key patterns (if exists)
9. `AGENTS.md` — codebase conventions (if exists)
10. The design doc from RALPH.md Documents.design (if configured) — UI/UX guidelines

Build a mental map of **all three** sources:

**PRD features:**

Parse the PRD for feature sections dynamically. Look for `## N.` or `### N.N` headings under the Features section. Each numbered feature section is a potential sprint source.

| PRD Section | Feature | Sprint Status |
|-------------|---------|---------------|
| [N.1] | [Feature name from heading] | Check archive for matching sprint IDs |
| [N.2] | [Feature name from heading] | Check archive/current for matching IDs |
| ... | ... | ... |

To determine sprint status: check archived sprint directories and their prd.json files for `source: "prd"` and matching `sourceItem` values. Also check the current prd.json. If a feature has been the source for a completed (all stories pass) and archived sprint, mark it as "Complete". If it's the current sprint, mark it as "In Progress". Otherwise, mark it as "Not Started".

**Backlog items:**

If the backlog file exists, parse each section heading. Check the `**Status:**` field — items that say "Complete" or "Done" are finished. Everything else is available.

| # | Item | Status | Priority |
|---|------|--------|----------|
| 1 | [Title] | [Status from doc] | [Priority from doc] |
| ... | ... | ... | ... |

**Tech debt:**

If the tech debt file exists, parse the active items. Each item typically has an ID (TD-NNN), severity (High/Medium/Low), and effort (Trivial/Small/Medium/Large). Items in "Resolved Items" are already fixed — only active items matter.

| ID | Title | Severity | Effort |
|----|-------|----------|--------|
| TD-NNN | [Title] | [Severity] | [Effort] |
| ... | ... | ... | ... |

---

## Step 2: Identify the Next Sprint

Present **all three** sources to the user. Show what's available from each:

```
## Sprint Sources

### PRD Features
- Completed: [list completed features]
- In Progress: [current sprint feature, if any]
- Next up: **[Section N.N: Feature Name]** (or "All v1 features complete")
- Later: [features marked as "later" or post-v1, if any]

### Backlog
[If no backlog file or empty: "No backlog items" and skip.]
- Completed: [list completed items]
- Available: [list items where Status != Complete/Done]

### Tech Debt
[If no tech debt file or no active items: "No active tech debt" and skip.]

[Group active items by effort:]
- **Can fold into next sprint** (Trivial/Small): [list TD-IDs + titles]
- **Could be its own sprint** (Medium/Large): [list TD-IDs + titles, with severity noted — High-severity items should be called out]
```

### Priority Recommendations

Use this priority order when making recommendations:

1. **Any v1/MVP feature in the PRD that's incomplete** (highest priority)
2. **High-priority items from the backlog**
3. **High-severity tech debt items with Medium/Large effort** (these warrant their own sprint)
4. **Other backlog items**
5. **User can always override**

Trivial/Small tech debt items don't get their own sprint option — they're noted as things that can be folded into whatever sprint is selected. This keeps the decision focused on meaningful work rather than offering a sprint for a one-line fix.

Present options to the user with the recommendation:

- **[PRD Feature Name]** — next PRD feature (Recommended if v1 features remain)
- **[Backlog Item: Title]** — from the backlog doc
- **[Tech Debt: TD-NNN Title]** — only for Medium/Large effort items
- **Something else** — let user specify

Ask: "Which one should we sprint on?"

---

## Step 3: Archive Current Sprint

If `scripts/ralph/prd.json` exists and has stories:

1. Count completed vs total stories
2. **If incomplete stories remain**, warn the user:
   > "This sprint has [N] incomplete stories out of [total]. Archive anyway?"

   Wait for confirmation before proceeding. If the user declines, stop — they may want to finish the current sprint first.

3. **If confirmed or all stories are complete**, archive:

   ```bash
   DATE=$(date +%Y-%m-%d)
   # Strip the branch prefix (e.g., "ralph/") from branchName to get the feature name
   FEATURE=$(echo "[branchName from prd.json]" | sed 's|^[^/]*/||')
   ARCHIVE_DIR="scripts/ralph/archive/$DATE-$FEATURE"

   # If directory already exists (same feature, same day), append a counter
   if [ -d "$ARCHIVE_DIR" ]; then
     COUNTER=2
     while [ -d "${ARCHIVE_DIR}-${COUNTER}" ]; do
       COUNTER=$((COUNTER + 1))
     done
     ARCHIVE_DIR="${ARCHIVE_DIR}-${COUNTER}"
   fi

   mkdir -p "$ARCHIVE_DIR"
   cp scripts/ralph/prd.json "$ARCHIVE_DIR/"
   cp scripts/ralph/progress.txt "$ARCHIVE_DIR/"
   ```

4. After archiving, reset `progress.txt` with a fresh header (preserve the Codebase Patterns section from the old progress.txt at the top, since those patterns carry forward).

If `scripts/ralph/prd.json` does not exist, skip this step entirely.

---

## Step 4: Generate Stories

Based on which source the user selected, extract the details needed to write stories.

### From PRD Section

Read the specific PRD feature section in detail. Extract:

- **Requirements** listed in the section (FR-X.Y.Z numbered items)
- **Data models** from the Data Model section that relate to this feature
- **User flows** or interaction descriptions if present
- **UI specs** from the design doc (if configured in RALPH.md Documents.design)
- **API integrations** or external services mentioned

### From Backlog Item

Read the specific backlog item section in detail. Extract:

- **Problem** — what's wrong and why it matters
- **Decided Approach** — the specific implementation plan (if documented)
- **What Remains** — tables or lists of concrete work items
- **PRD Sections Affected** — for cross-referencing requirements

### From Tech Debt Item

Read the specific tech debt item in the tech debt file. Extract:

- **Description** — what's wrong and why it matters
- **Severity / Effort** — prioritization context
- **Files** — affected file paths (these become the implementation targets)
- **Fix approach** — if documented, use it as the implementation plan

Tech debt sprints tend to be more mechanical and well-scoped than feature work — the problem and fix are usually clear, so stories can be more specific in their acceptance criteria.

### Common to All Sources

Also read:

- `progress.txt` Codebase Patterns section — reference existing code patterns in story notes
- Existing codebase structure — know what already exists by scanning directories

**Before writing stories**, explore the codebase to understand current patterns relevant to the sprint. Use Grep/Glob/Read to find:

- Files that will be created or modified
- Existing patterns to follow or refactor
- Dependencies between components

This exploration makes acceptance criteria specific and accurate rather than generic.

### Folding in Trivial/Small Tech Debt

If there are Trivial or Small effort tech debt items that relate to the sprint feature area, fold them into the sprint as additional stories or extra acceptance criteria on existing stories. Mention this to the user:

> "I've folded in [TD-NNN: title] since it's a small fix in the same area."

### Story Generation Rules

1. **Order by dependency**: DB schema/migrations first -> backend logic/utilities -> UI components -> screens/pages -> integration/polish
2. **One context window per story**: Each story must be completable in ~30-60 minutes by the agent. If you cannot describe the change in 2-3 sentences, it is too big — split it.
3. **Acceptance criteria from source**: Pull specific requirements directly from the PRD section, backlog approach, or tech debt description — don't invent new ones.
4. **Quality command in every story**: Include the quality check from RALPH.md Quality Commands (e.g., "Typecheck passes", "Lint passes") as acceptance criteria in every story. Use whichever commands are configured.
5. **testFlow only if E2E configured**: If RALPH.md has `e2e_single` configured, set `testFlow` to the appropriate test flow path for stories that create new screens or user-facing flows. Set to `null` for backend-only stories, refactors, or non-UI changes. If `e2e_single` is not configured, always set `testFlow` to `null`.
6. **5-8 stories per sprint**: If a feature would need more, consider splitting into two sprints. If a tech debt item only needs 2-3 stories, that's fine too.
7. **Story notes reference the codebase**: Include specific file paths, existing patterns to follow (e.g., "Follow the same pattern as `src/hooks/useAuth.ts` for the new hook"), and implementation hints. Never write generic notes.
8. **ID prefix**: Use a short, memorable abbreviation derived from the feature name (e.g., AUTH, DASH, UPLOAD, SYNC, NOTIF). Keep it 3-6 characters.
9. **Branch name**: Use `[branch_prefix from RALPH.md][kebab-case-feature-name]`. For example, if `branch_prefix` is `ralph/` and the feature is "User Dashboard", the branch is `ralph/user-dashboard`.
10. **No story depends on a later story**: If story 3 needs something from story 5, reorder them.

### Story Structure

Each story in the `userStories` array follows this structure:

```json
{
  "id": "PREFIX-NNN",
  "title": "Concise imperative title",
  "description": "What needs to happen and why",
  "acceptanceCriteria": [
    "Specific, testable criterion from source doc",
    "Another criterion",
    "Quality command passes (e.g., Typecheck passes)"
  ],
  "priority": 1,
  "passes": false,
  "testFlow": "path/to/test.yaml or null",
  "notes": "Implementation hints referencing existing patterns and specific file paths"
}
```

### prd.json Structure

The complete prd.json includes source metadata so `/start` Case D knows which item to mark complete when the sprint merges:

```json
{
  "project": "[Project Name from RALPH.md]",
  "source": "prd",
  "sourceItem": "3.1",
  "branchName": "ralph/feature-name",
  "description": "Feature description — what this sprint delivers",
  "userStories": [
    { "...story objects..." }
  ]
}
```

**Source field values by sprint type:**

| Sprint source | `source` value | `sourceItem` value | Example |
|---------------|----------------|--------------------|---------|
| PRD feature section | `"prd"` | Section number as string | `"3.1"` |
| Backlog item | `"backlog"` | Item number as integer | `5` |
| Tech debt item | `"tech-debt"` | Tech debt ID as string | `"TD-003"` |

---

## Step 5: Review and Write

Show the complete generated `prd.json` to the user. Highlight:

- **Total number of stories** and whether that's a reasonable sprint size
- **Which stories have E2E tests** (non-null testFlow)
- **The dependency order** — confirm that no story depends on a later one
- **Source** — which PRD section, backlog item, or tech debt item this sprint covers
- **Folded-in tech debt** — if any Trivial/Small items were included

Ask: "Does this look good? Any stories to add, remove, or adjust?"

Offer options:
- **Looks good, create the sprint**
- **I have adjustments** — let user describe changes, then regenerate the affected stories

### After Approval

1. Write to `scripts/ralph/prd.json`
2. Reset `scripts/ralph/progress.txt` — keep the Codebase Patterns section at the top if it exists, clear all previous sprint entries below it. If no Codebase Patterns section exists, create a minimal header:
   ```
   # Ralph Progress Log

   ## Codebase Patterns
   [Will be populated as stories are completed]

   ---
   ```
3. Show the sprint summary:

```
## Sprint Created!

Feature: [name]
Source: [PRD section N.N / Backlog item #N / Tech debt TD-NNN]
Branch: [branchName]
Stories: [count]
E2E tests: [count with testFlow] / [total]

Run /start to begin working on the first story.
```

---

## Right-Sized Stories — Reference

**Good story size (fits one context window):**
- Add a database table and migration
- Create a reusable UI component
- Add a server action or API endpoint with logic
- Wire up a screen that uses existing components and hooks
- Add filtering or sorting to an existing list
- Refactor a module to a new pattern

**Too big (split these):**
- "Build the entire dashboard" — split into: schema, queries, UI components, layout, filters, integration
- "Add authentication" — split into: schema, middleware, login UI, signup UI, session handling
- "Refactor the API layer" — split into one story per endpoint or pattern change

**Rule of thumb:** If you cannot describe the change in 2-3 sentences, it is too big.

---

## Checklist Before Saving

Before writing prd.json, verify:

- [ ] Gate passed — PRD exists at the RALPH.md Documents.prd path
- [ ] All three sources were checked (PRD, backlog, tech debt)
- [ ] Current sprint archived (if one existed)
- [ ] Each story is completable in one context window (~30-60 min)
- [ ] Stories are ordered by dependency (schema -> backend -> UI -> integration)
- [ ] Every story has quality command criteria from RALPH.md
- [ ] testFlow is set correctly (only if e2e_single is configured, only for UI stories)
- [ ] Acceptance criteria are specific and verifiable (not vague)
- [ ] No story depends on a later story
- [ ] Story notes reference specific files and existing patterns
- [ ] 5-8 stories (split into multiple sprints if more)
- [ ] `source` and `sourceItem` fields are set correctly
- [ ] Branch name uses the prefix from RALPH.md Git.branch_prefix
- [ ] User has reviewed and approved the sprint
