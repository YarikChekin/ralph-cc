# Changelog

## 2.0.0 — 2026-05-27

Major release. Ports the audit-loop evolution back from a year of in-flight learning. Breaking change in agent shape and prd.json AC format; runtime back-compat preserved via legacy-string-AC support and optional RALPH.md sections.

### Added

- **New `auditor` agent** — long-lived teammate replacing `story-reviewer`. Three modes:
  - Per-story (after every `feat:` commit, when `Audit.mode=per-story`)
  - Sprint-close branch sweep (10-point checklist before merge)
  - PRD review (pre-sprint quality gate on draft prd.json)
  Writes durable reports to `scripts/ralph/audit-reports/` (configurable via `Audit.reports_dir`). Maintains cross-session memory in `PATTERNS.md` and `audit-progress.txt`.
- **New `/audit` skill** — thin wrapper for ad-hoc auditor invocation outside the Ralph loop.
- **`RALPH.md` Audit section** — `mode` toggle (`off | sprint-close | per-story`) and `reports_dir`. Defaults to `sprint-close` for back-compat with v1.
- **`RALPH.md` Merge section** — `mode` toggle (`local | pr`) and `branch_base`. PR mode adds `/start` Case D2 for PR state handling (awaiting review / changes requested / approved → merge).
- **`RALPH.md` Github section** — `enabled` toggle. When true, `/start` surfaces open GitHub Issues alongside the sprint dashboard; `/new-sprint` accepts issues as a sprint source via `source: "github-issue"` + `sourceIssues: [N]`.
- **Live context-discipline check in `/start`** — reads `/ctx` between stories and recommends `/wrap` at 40% (nudge) / 60% (strong). Replaces the PRD-authored `wrapPoints` model.
- **Dual-cleanup `/wrap`** — when `Audit.mode=per-story` and the auditor teammate is alive, `/wrap` signals the auditor to flush state first, awaits ack, then proceeds. Team config persists across sprints by design.
- **`/start` Case A** — uncommitted changes are detected and surfaced up-front.
- **Humanly-gated ACs** — acceptance criteria can now be objects (`{ text, humanGated? }`). `humanGated: true` ACs return `PASS-PENDING-HUMAN` from the auditor; the lead waits for operator confirmation before flipping `passes: true`.
- **`audit-reports/` directory + `PATTERNS.md` stub** scaffolded by `/ralph-init`.

### Changed

- `/start` now respects `Audit.mode` (off / sprint-close / per-story) and `Merge.mode` (local / pr). Old behavior is preserved when sections are missing.
- `/new-sprint` accepts GitHub Issues as a source (when enabled) and now sends the draft PRD through the auditor when `Audit.mode=per-story` (Step 5).
- `prd.json.example` template uses the new AC object form with a humanGated example.
- `scripts/ralph/prompt.md` template updated with audit-gate logic and AC format note.
- `/ralph-help` adds `/audit` to the command list and notes the Audit/Merge toggles.

### Removed

- **`story-reviewer` agent** — superseded by `auditor`. Update any docs or scripts that referenced it.

### Migration

- v1 `RALPH.md` without `Audit` / `Merge` / `Github` sections continues to work — defaults give back-compat behavior (sprint-close audit only, local merge, no GitHub surfacing).
- v1 `prd.json` with string-form acceptance criteria continues to work — auditor treats strings as `humanGated: false`.
- v1 `prd.json` with a `wrapPoints` array is harmless; `/start` ignores it and uses the live `/ctx` check instead.

## 1.0.0 — 2026-03-16

Initial release.

- 11 skills: /ralph-init, /prd-plan, /new-sprint, /start, /ralph, /wrap, /log, /new-idea, /promote-idea, /tech-debt-review, /test
- 1 agent: story-reviewer
- Project templates for scaffolding
- Claude Code plugin distribution
