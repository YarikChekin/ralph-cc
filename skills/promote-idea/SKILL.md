---
name: promote-idea
description: Use when the user wants to move a researched idea from the ideas directory into the backlog for sprint planning, or when prompted at the end of /new-idea
---

# /promote-idea — Move an Idea to the Backlog

Promotes a researched idea from the ideas directory into the backlog file, resolving open questions and finalizing the approach so it's ready for `/new-sprint` generation.

## Before Starting

Read `RALPH.md` to find:
- `Documents.ideas` — path to the ideas index file (derive the ideas directory from this path)
- `Documents.backlog` — path to the backlog file

If `RALPH.md` doesn't exist or is missing these paths, tell the user: "RALPH.md is missing or incomplete. Run `/ralph-init` to set up your project."

## Step 1: Show All Ideas

Scan the ideas directory for idea files (skip `_index.md`). Read each file to get status, effort, value, and gauge how fleshed out it is (has market research? technical considerations? open questions?).

Show **all** ideas in a single table, sorted by readiness — most fleshed out on top:

1. `researched` ideas first (ready to promote)
2. `idea` status next (brainstormed but not fully researched)
3. `parked` ideas last

```
## Ideas

| # | Idea | Status | Effort | Value |
|---|------|--------|--------|-------|
| 1 | Feature X | researched | Easy | High |
| 2 | Feature Y | researched | Medium | High |
| 3 | Feature Z | idea | ? | ? |
```

Use AskUserQuestion to let the user pick which idea to promote (or skip this if they already specified one, or if flowing directly from `/new-idea`).

**If the user picks an idea with `status: idea`** (not yet researched), explain that promotion requires research first and offer to research it now using `/new-idea`. After research completes and the idea is updated to `status: researched`, loop back and offer to promote it.

If there are no ideas at all, suggest `/new-idea` to brainstorm a new one.

## Step 2: Resolve Open Questions

This is the critical step. Read the idea file and find the `## Open Questions` section.

**Do NOT skip or copy these questions verbatim into the backlog doc.** Each question must be answered before promotion.

Walk through each open question one at a time with the user using AskUserQuestion. For each question:
- Present the question with relevant context from the idea doc
- Offer 2-3 concrete options based on the research already done
- Record the user's decision

If there are no open questions, confirm the proposed solution with the user: "The idea has no open questions. Does the proposed solution still match what you want to build?"

## Step 3: Write the Backlog Section

Read the backlog file (from RALPH.md `Documents.backlog`) to determine:
- The next section number (look at the last `## N.` heading)
- The existing format and tone

If the backlog file doesn't exist, create it with this structure:

```markdown
# Post-MVP Improvements

Backlog of improvements and feature ideas. Use `/promote-idea` to add researched ideas, `/log improvement` for quick captures.

<!-- Add new improvements below this line -->
```

Write a new section following the **exact backlog format**:

```markdown
## [N]. [Title]

**Date:** [YYYY-MM-DD]
**Status:** Planned
**Priority:** [High/Medium/Low — use the Value from the idea doc]
**Source:** [ideas/filename.md](./ideas/filename.md)

### Problem

[From the idea doc's Problem section — can be lightly edited for conciseness]

### Decided Approach

[Convert the idea's "Proposed Solution" into a "Decided Approach". This is where the resolved open questions get incorporated. Write with certainty — "We will..." not "We could..."]

### What Remains

[Concrete work items — what needs to be built. Pull from Technical Considerations in the idea doc. Format as a table or bullet list of specific tasks.]

### PRD Sections Affected

[From the idea doc's PRD Mapping section]
```

**Format rules:**
- **DO NOT** include: Effort, Value, Market Research, Competitive Analysis, or Technical Options sections. The backlog is a backlog, not a research doc.
- **DO NOT** include open questions — they should all be resolved by now.
- **DO NOT** include "Alternatives Considered" unless there were meaningful rejected approaches worth documenting.
- **DO** use "Decided Approach" (not "Proposed Solution") — the decision is made.
- **DO** end the section with `---` (horizontal rule separator).
- **DO** insert before the `<!-- Add new improvements below this line -->` comment.

## Step 4: Review with User

Show the complete backlog section to the user before writing it. Ask:

"Does this look right? Any changes before I add it to the backlog?"

Use AskUserQuestion:
- **Looks good, promote it**
- **I have changes** — incorporate feedback, re-show

## Step 5: Write Changes

After approval, make three changes:

### 1. Append to the backlog file
Insert the new section before the `<!-- Add new improvements below this line -->` comment.

### 2. Update the idea file status
Change `**Status:** researched` to `**Status:** planned` in the idea doc.

Remove the `## Open Questions` section entirely (or replace with "Resolved — see backlog item #N").

### 3. Update the ideas index
In the ideas index file (from RALPH.md `Documents.ideas`), update the idea's status from `researched` to `planned`.

## Step 6: Confirm

```
Promoted to [backlog file path] as item #[N].

When you're ready to build it, run /new-sprint — it will
pick this up from the backlog automatically.
```
