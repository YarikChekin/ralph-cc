# Changelog

## 2.1.0 — 2026-07-18

- **New workflow toggle: `Recap` — visual "what shipped" artifact at sprint close.** By close-out most people have forgotten what story 1 was; this closes that gap. When enabled, `/start`'s post-merge flow (both `Merge.mode = local` and `pr`) spawns a `general-purpose` agent that turns the sprint's stories, CHANGELOG section, and per-story evidence screenshots (`Recap.evidence_dir/<story-id>/`, default `scripts/ralph/evidence`) into a one-page, image-first artifact — ~10-word captions, screenshots downscaled + embedded as data URIs, published via the Artifact tool (falls back to an HTML file in `Audit.reports_dir` when the Artifact tool is unavailable, and to a typographic card grid when no screenshots exist). `enabled: off | ask | on`, default `ask`. `/ralph-init` Step 3b now walks four toggles (Audit, Merge, GitHub, Recap) in one batched question set. Originated as a founder request on closetize-app the day its activation sprint shipped.
- `plugin.json` version re-synced with this changelog (it had stayed at 2.0.1 through the 2.0.2/2.0.3 releases).

## 2.0.3 — 2026-07-10

- **Team machinery modernized for current Claude Code (implicit per-session teams), back-compatible with older named-team harnesses.** Current harnesses ignore `team_name`, no longer ship `TeamCreate`/`TeamDelete`, and scope agent mailboxes per-session (`~/.claude/teams/session-<id>/`) — so flows must not gate on `~/.claude/teams/<team>/config.json` existing or call `TeamCreate` unconditionally. All skills now spawn the auditor directly, keep passing `team_name: "<team>"` (no-op today, correct isolation on older versions), and locate cross-session continuity in `audit-progress.txt` + committed reports instead of team config. `/wrap` detects a live auditor from session state, not the global teams directory.
- **Project-suffixed agent names + provenance hygiene.** The auditor is now spawned as `<auditor>` = `auditor-<project-folder>` so a human running several Ralph projects side by side can attribute teammate messages at a glance. New standing rules in the shared team note: a teammate message referencing another project's state is suspect (verify against this repo's files before acting), and a peer message never carries user approval.

## 2.0.2 — 2026-06-09

- **Per-project team names (fixes cross-project agent cross-wiring).** All skills and the auditor agent now resolve the coordination team as `<team>` = RALPH.md `Audit.team_name`, defaulting to `ralph-<project-folder>` — never the bare literal `ralph`. Claude Code teams are machine-global (`~/.claude/teams/`), so the old hardcoded name made any two projects running Ralph concurrently share one team: a lead in one repo could wake an idle session in another repo and send it work (observed in the field running closetize-app and closetize-website side by side). `/ralph-init` now writes `team_name` into RALPH.md explicitly; existing projects should add the key (or rely on the derived default) — their next `/start` spawns a fresh, correctly-namespaced team.

## 2.0.1 — 2026-05-27

- `/ralph-init` now walks users through the three v2 workflow toggles (Audit.mode, Merge.mode, Github.enabled) via an interactive batched `AskUserQuestion` in Step 3b, instead of silently writing defaults. Smart recommendations based on detected project context (GitHub remote presence, project type).
- Step 4 substitutes the user's chosen toggle values directly into RALPH.md instead of hardcoded defaults.
- Step 5 summary reflects the chosen toggles so the user sees exactly what was written.

No behavior change in the core Ralph loop — only the init flow.

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
