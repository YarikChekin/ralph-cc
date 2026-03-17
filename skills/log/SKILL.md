---
name: log
description: Use when noticing a bug or improvement idea mid-session and wanting to capture it without losing focus on current work
---

# /log — Quick Capture

Capture bugs or improvement ideas with just enough context to act on later. Two types, two existing files, zero workflow interruption.

## Usage

```
/log bug: signup button doesn't disable after tap
/log improvement: sort items by category on the list screen
/log the date picker clips on small screens
```

## Step 1: Read RALPH.md

Read `RALPH.md` to find:
- `Documents.issues` — file path for bug entries
- `Documents.backlog` — file path for improvement entries

If `RALPH.md` doesn't exist or is missing these paths, tell the user: "RALPH.md is missing or incomplete. Run `/ralph-init` to set up your project."

## Step 2: Parse Input

Extract from the user's message:

1. **Type**: `bug` or `improvement`
   - If no prefix, classify: broken/wrong/erroring -> `bug`, works but could be better -> `improvement`
   - If ambiguous, ask: "Is this broken (bug) or a wishlist item (improvement)?"
2. **Description**: The rest of the message

## Step 3: Ask Clarifying Questions

Ask just enough to make the entry actionable later. Keep it to 2-3 questions max.

**For bugs:**
- "What screen or feature is this on?" (if not obvious from description)
- "What did you expect to happen vs what actually happened?"
- "Is this blocking anything right now?" (determines severity)

**For improvements:**
- "What screen or feature does this affect?" (if not obvious)
- "What should it do differently, and why is that better?"

Skip questions where the answer is already clear from the description or current session context. Don't ask more than necessary — this is quick capture, not investigation.

## Step 4: Gather Context (silently)

1. `git branch --show-current`
2. Check `scripts/ralph/prd.json` for current story (if it exists)

## Step 5: Route and Append

### Bug -> Issues File

Read the issues file (from RALPH.md `Documents.issues`). If the file doesn't exist, create it from the template:

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

Find the next issue number, append a row:

```
| [next #] | [Severity] | [Feature] | [Description — include what was expected vs actual] | Logged |
```

Severity (based on user answers):
- **Blocker**: Can't continue, core feature broken
- **Major**: Feature broken, workaround exists
- **Minor**: Cosmetic or UX issue (default if unclear)
- **Polish**: Slight improvement to existing behavior

### Improvement -> Backlog File

Read the backlog file (from RALPH.md `Documents.backlog`). If the file doesn't exist, create it with this structure:

```markdown
# Post-MVP Improvements

Backlog of improvements and feature ideas. Use `/promote-idea` to add researched ideas, `/log improvement` for quick captures.

<!-- Add new improvements below this line -->
```

Find the last numbered section, append before the `<!-- Add new improvements below this line -->` comment:

```markdown
---

## [next number]. [Short Title]

**Date:** [YYYY-MM-DD]
**Status:** Idea — quick capture
**Source:** Noticed during [current branch / story context]

### What
[2-3 sentences from the user's description and answers]

### Why
[Brief reasoning from the user's answers]

### PRD Sections Affected
[Best guess, or "TBD"]
```

## Step 6: Recommend Now vs Later

After logging, silently assess whether this is worth addressing now. Consider:

- Is this in code the user is actively touching this session?
- Is it a quick fix (one-liner, small tweak)?
- Is it related to the current sprint story?
- How complex is it?

Then give a **one-sentence recommendation** with a yes/no:

**Fix now signals:**
- Bug is in the current story's code -> "This is in the code you're working on right now — want to fix it while you're here?"
- Bug or improvement is trivial -> "This looks like a quick fix — want to handle it now?"

**Fix later signals:**
- Unrelated to current work -> "Logged for later."
- Would take significant effort -> "This is bigger than a quick fix — logged for a future sprint."
- Improvement that needs design thought -> "Logged. This might be worth a `/new-idea` session when you have time."

**Rules for this step:**
- One sentence, one question. Not a deep analysis.
- If the user says "later" or ignores the suggestion, move on immediately.
- If the user says "yes, let's do it now," proceed to fix it — you're no longer in `/log` mode.
- Never pressure. The default is "logged for later."

## Step 7: Confirm and Stop

If the user chose "later" (or you recommended later and they didn't respond), show:

```
Logged [bug/improvement] #[number]: [short description]
-> [file path]
```

Then STOP. Do not offer further suggestions or ask more questions. Return control to whatever the user was doing.

## Rules

- **Don't duplicate**: Scan the target file first. If a similar entry exists, tell the user instead of creating a duplicate.
- **Don't investigate**: Log it and move on. Debugging is a separate activity (unless the user accepts a "fix now" recommendation).
- **Don't upgrade scope**: If someone says "improvement" don't push them toward `/new-idea`. They chose `/log` for a reason. You may mention it as an option in Step 6 but don't insist.
- **Respect existing format**: Match the exact table format in the issues file and the section format in the backlog file.
