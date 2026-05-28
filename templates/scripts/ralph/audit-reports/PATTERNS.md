# Auditor PATTERNS

This file is the auditor's distilled cross-session memory. The auditor reads it at the start of every session and curates it as it discovers new patterns.

**Curation rules:**
- Target ≤150 lines total. Quality over quantity.
- Replace stale entries (not just append). Merge duplicates.
- Group by category: schema gotchas, common miss patterns, project conventions, recurring spec errors.
- Each entry should be load-bearing — if removing it wouldn't hurt a future audit, drop it.

---

## Schema gotchas

_Examples — replace with actual project-specific schema landmines as you encounter them:_
- Column X lives on table A, not table B (commonly confused).
- Field Y is read at insert time only; updates are silent no-ops.

## Common miss patterns (project-specific)

_Add concrete examples beyond the abstract categories in `agents/auditor.md`:_
- Story Z added column W; the consumer at `src/foo.ts` does not select it. Always grep consumers when a story adds a column.

## Project conventions

_Examples:_
- Branch names follow `<prefix>/<feature>` per `RALPH.md` Git.branch_prefix.
- E2E flows live under the path matching `RALPH.md` `e2e_single` template (e.g., `e2e/<feature>/<screen>.test.ts`).
- Migrations must use `IF NOT EXISTS` for idempotency.

## Recurring spec errors in PRDs

_Track PRD bugs that have shipped past you:_
- Vague AC pattern "user can do X" without specifying success criteria.
- Missing humanGated flag on operator-portal ACs.
