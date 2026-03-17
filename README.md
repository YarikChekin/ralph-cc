# ralph-cc

A spec-driven development workflow for Claude Code.

Ralph-cc gives you structured sprint planning, session management, and an idea-to-execution pipeline -- all running inside Claude Code as native skills.

Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/) and [snarktank/ralph](https://github.com/snarktank/ralph).

## What it does

- **No code without a plan.** Forces a PRD before any sprint begins.
- **One story per session.** Each agent gets clean context -- no degradation.
- **Session continuity.** WIP commits, progress logs, and handoff notes mean nothing is lost between sessions.
- **Full pipeline.** Ideas -> backlog -> sprints -> execution -> review -> merge.

## Quick Start

### Install the plugin

```
/plugin marketplace add YarikChekin/ralph-cc
/plugin install ralph-cc
```

### Set up your project

```
/init          # Scaffold ralph into your project
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
| `/new-sprint` | Generate the next sprint from PRD/backlog |
| `/start` | Session dispatcher -- picks up where you left off |
| `/ralph` | Quick sprint dashboard |
| `/wrap` | Clean session handoff |
| `/log` | Quick-capture bugs or improvements |
| `/new-idea` | Brainstorm and research feature ideas |
| `/promote-idea` | Move an idea to the backlog |
| `/tech-debt-review` | Assess tech debt health |
| `/test` | Guided manual testing |

## Workflow

```
/init                    Scaffold project files + RALPH.md
  |
  v
/prd-plan                Define or audit product requirements
  |                      (required before any sprint)
  v
/new-sprint              Pick feature -> generate prd.json with stories
  |
  v
/start ──────────────── Session dispatcher (run every session)
  |                        |
  v                        v
Ralph loop               /wrap (end session cleanly)
  | (one story            |
  |  per session)         v
  |                     /start (next session picks up)
  v
All stories done?
  |
  |-- No  -> /start again
  |
  |-- Yes -> Review + merge
  |            |
  |            v
  |          /new-sprint (next feature)
  |
  v
Side workflows (anytime):
  /log              -> capture bug/improvement
  /new-idea         -> brainstorm feature idea
  /promote-idea     -> move idea to backlog
  /tech-debt-review -> assess debt health
  /test             -> manual testing loop
  /ralph            -> quick sprint dashboard
```

## Credits

Based on [snarktank/ralph](https://github.com/snarktank/ralph) (MIT) and [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/).

## License

MIT
