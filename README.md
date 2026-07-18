# ralph-cc

A spec-driven development workflow for Claude Code.

Ralph-cc gives you structured sprint planning, session management, a long-lived audit teammate, and an idea-to-execution pipeline — all running inside Claude Code as native skills and agents.

Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/) and [snarktank/ralph](https://github.com/snarktank/ralph).

## What it does

- **No code without a plan.** Forces a PRD before any sprint begins.
- **One story per session.** Each agent gets clean context — no degradation.
- **Independent audit.** A long-lived auditor teammate verifies every `feat:` commit against acceptance criteria (when enabled), writes durable reports, and signs off before the lead advances.
- **Session continuity.** WIP commits, progress logs, dual-cleanup auditor wraps, and handoff notes mean nothing is lost between sessions.
- **Full pipeline.** Ideas → backlog → sprints → execution → audit → review → merge.

## Quick Start

### Install the plugin

```
/plugin marketplace add YarikChekin/ralph-cc
/plugin install ralph-cc
```

### Set up your project

```
/ralph-init    # Scaffold ralph into your project
/prd-plan      # Define your product requirements
/new-sprint    # Generate your first sprint
/start         # Begin working
```

### Manual install (without plugin)

```bash
git clone https://github.com/YarikChekin/ralph-cc
cp -r ralph-cc/skills/ your-project/.claude/skills/
cp -r ralph-cc/agents/ your-project/.claude/agents/
cp -r ralph-cc/templates/* your-project/
```

## Skills Reference

| Skill | Description |
|-------|-------------|
| `/ralph-init` | Scaffold ralph into a project |
| `/prd-plan` | Create or audit product requirements |
| `/new-sprint` | Generate the next sprint from PRD / backlog / tech debt / GitHub Issues |
| `/start` | Session dispatcher — picks up where you left off, runs the audit gate |
| `/ralph` | Quick sprint dashboard |
| `/wrap` | Clean session handoff (with auditor dual-cleanup) |
| `/audit` | Spawn the auditor agent for ad-hoc story / branch / PRD review |
| `/log` | Quick-capture bugs or improvements |
| `/new-idea` | Brainstorm and research feature ideas |
| `/promote-idea` | Move an idea to the backlog |
| `/tech-debt-review` | Assess tech debt health |
| `/test` | Guided manual testing |
| `/ralph-help` | Quick command reference |

## Agents

| Agent | Description |
|-------|-------------|
| `auditor` | Long-lived audit teammate. 3 modes: per-story (after each feat: commit), sprint-close (branch-level sweep), PRD review (pre-sprint quality gate). Writes durable reports. |

## Workflow

```
/ralph-init             Scaffold project files + RALPH.md (with Audit/Merge/Github defaults)
  |
  v
/prd-plan               Define or audit product requirements
  |                     (required before any sprint)
  v
/new-sprint             Pick source -> generate prd.json with stories
  |                     (Audit.mode=per-story: auditor reviews draft PRD first)
  v
/start ──────────────── Session dispatcher (run every session)
  |                       |
  |   Case A: uncommitted changes -> commit/discard/continue
  |   Case B: WIP commit -> resume interrupted story
  |   Case C: normal continuation -> next story
  |   Case D: sprint complete -> sprint-close audit + merge (local)
  |   Case D2: open PR -> reviews / changes / merge (pr mode)
  v
Ralph loop              Worker agent + (optional) auditor teammate
  | (one story            |
  |  per session)         v
  v                     /wrap (end session cleanly — auditor dual-cleanup if alive)
                          |
                          v
                        /start (next session picks up)
  |
  v
All stories done?
  |
  |-- No  -> /start again
  |
  |-- Yes -> /start Case D (or D2) handles audit + merge
  |
  v
Side workflows (anytime):
  /log              -> capture bug/improvement
  /new-idea         -> brainstorm feature idea
  /promote-idea     -> move idea to backlog
  /tech-debt-review -> assess debt health
  /test             -> manual testing loop
  /audit            -> ad-hoc auditor invocation
  /ralph            -> quick sprint dashboard
```

## Configuration (RALPH.md)

Three optional sections control how aggressive the workflow is. All have safe defaults so a v1-style RALPH.md (without these sections) still works.

### Audit

```
## Audit
mode: sprint-close          # off | sprint-close | per-story
reports_dir: scripts/ralph/audit-reports
```

- `off` — no auditor involvement. The lead flips `passes: true` itself.
- `sprint-close` (default) — auditor runs once before merge as a branch-level sweep.
- `per-story` — strict. The auditor is spawned as a long-lived teammate; it audits **after every `feat:` commit**, and the lead does NOT flip `passes: true` until the auditor returns `SIGN OFF`. The lead also sends the draft PRD through the auditor in `/new-sprint` Step 5.

### Merge

```
## Merge
mode: local                  # local | pr
branch_base: main
```

- `local` (default) — `/start` Case D merges directly to `branch_base`.
- `pr` — `/start` Case D opens a PR via `gh pr create`; Case D2 handles the post-review states (awaiting / changes requested / approved → merge). The plugin does NOT ship a reviewer dispatch script — your project decides how reviewers run (manual, CI, Claude Code agent dispatch, etc.).

### Recap

```
## Recap
enabled: ask                 # off | ask | on
evidence_dir: scripts/ralph/evidence
```

A one-page, image-first "what shipped" artifact built by an agent at sprint close — for the human who ran the sprint, because by close-out most people have forgotten what story 1 was. Uses per-story screenshots from `evidence_dir/<story-id>/` when they exist (falls back to a typographic card grid when they don't), captions of ~10 words, published via the Artifact tool. `ask` (default) offers it once at each sprint close; `on` builds it automatically.

### Github

```
## Github
enabled: false               # if true, /start surfaces gh issues, /new-sprint accepts issue sources
```

When enabled, `/start` shows open GitHub Issues alongside the sprint dashboard and lets you pick one to work on (the lead reads `gh issue view`, treats the issue as the task spec, and includes `Fixes #N` in the commit body for auto-close on merge). `/new-sprint` can also build a sprint from one or more open issues (`source: "github-issue"`, `sourceIssues: [N]`).

`gh` CLI must be installed and authenticated; if it isn't, ralph-cc warns once and falls back to local file sources.

## Acceptance criteria (v2)

Stories use object-form ACs: `{ "text": "...", "humanGated"?: true }`. Legacy string-form ACs are still accepted (treated as `humanGated: false`), so v1 prd.json files keep working.

`humanGated: true` flags an AC the auditor cannot verify alone — the operator must take action on a system the coding agent can't reach (a third-party dashboard, a real device, an app store portal). When the auditor encounters one, it returns `PASS-PENDING-HUMAN` and the lead surfaces the AC text to the operator before flipping `passes: true`.

## Migrating from v1

v2 is a breaking change in shape but preserves runtime back-compat:

| What changed | What to do |
|---|---|
| Agent: `story-reviewer` removed | Replaced by `auditor`. Update any project docs or scripts that referenced it. |
| AC format: string → object | v1 string ACs still work. New sprints emit object form; the auditor treats strings as `humanGated: false`. |
| `wrapPoints` array dropped from prd.json | Old `wrapPoints` arrays are simply ignored. `/start` decides wrap timing live via `/ctx`. |
| `RALPH.md` Audit / Merge / Github sections added | Optional. Missing sections default to v1 behavior (sprint-close audit only, local merge, no GitHub surfacing). |
| New `/audit` skill, new `auditor` agent | Auto-loaded with the plugin. No action needed. |

To opt into the new per-story audit gate or PR merge flow, add the relevant sections to your `RALPH.md` (see Configuration above).

## Credits

Based on [snarktank/ralph](https://github.com/snarktank/ralph) (MIT) and [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/).

## License

MIT
