# ralph-cc Design Spec

> A spec-driven development workflow for Claude Code — packaging the Ralph loop, session management, sprint planning, and idea pipeline as a distributable plugin.

**Date:** 2026-03-16
**Status:** Approved

---

## 1. Overview

ralph-cc is a Claude Code plugin that provides a structured, spec-driven development workflow. It manages the full lifecycle from product planning through sprint execution, session handoffs, bug tracking, and idea capture.

Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/) and [snarktank/ralph](https://github.com/snarktank/ralph) (MIT licensed). Extended with session management, backlog pipelines, testing workflows, and Claude Code-native distribution.

### What it solves

- **No structure** — "vibecoding" produces inconsistent results at scale. Ralph enforces plan-then-execute.
- **Context rot** — AI output degrades as context fills. Ralph executes one story per session with clean context.
- **Session continuity** — work is lost between sessions. Ralph tracks state, handoffs, and progress.
- **Planning gaps** — jumping into code without a PRD leads to scope creep and directionless sprints.

### Core principle

No code without a plan. No sprint without a PRD.

---

## 2. Distribution

### Primary: Claude Code Plugin

Published as a GitHub repo with plugin manifest. Users install via:

```bash
/plugin marketplace add <owner>/ralph-cc
/plugin install ralph-cc
```

Skills and agents are loaded globally — available in any project directory.

### Secondary: Manual Clone

For users without the plugin system or who prefer local control:

```bash
git clone https://github.com/<owner>/ralph-cc
cp -r ralph-cc/skills/ <project>/.claude/skills/
cp -r ralph-cc/agents/ <project>/.claude/agents/
```

Then manually copy templates from `ralph-cc/templates/` into the project.

### npm Package (tertiary)

Published to npm as `ralph-cc` for `npx ralph-cc` discoverability, but the plugin path is the primary install method.

---

## 3. Repo Structure

### Plugin manifest (.claude-plugin/plugin.json)
```json
{
  "name": "ralph-cc",
  "description": "Spec-driven development workflow — sprint planning, session management, and idea pipeline for Claude Code",
  "version": "1.0.0",
  "author": { "name": "<owner>" }
}
```

### Marketplace manifest (.claude-plugin/marketplace.json)
```json
{
  "name": "ralph-cc",
  "owner": { "name": "<owner>" },
  "plugins": [
    {
      "name": "ralph-cc",
      "source": ".",
      "description": "Spec-driven development workflow for Claude Code",
      "version": "1.0.0"
    }
  ]
}
```

### Directory layout
```
ralph-cc/
├── .claude-plugin/
│   ├── plugin.json              # Plugin manifest
│   └── marketplace.json         # Self-hosted marketplace listing
├── skills/
│   ├── init/SKILL.md            # /init — scaffold ralph into a project
│   ├── prd-plan/SKILL.md        # /prd-plan — create or audit product requirements
│   ├── new-sprint/SKILL.md      # /new-sprint — generate sprint from PRD
│   ├── start/SKILL.md           # /start — session dispatcher
│   ├── ralph/SKILL.md           # /ralph — sprint dashboard + kickoff prompt
│   ├── wrap/SKILL.md            # /wrap — clean session handoff
│   ├── log/SKILL.md             # /log — quick-capture bugs/improvements
│   ├── new-idea/SKILL.md        # /new-idea — brainstorm + research ideas
│   ├── promote-idea/SKILL.md    # /promote-idea — move idea to backlog
│   ├── tech-debt-review/SKILL.md # /tech-debt-review — assess debt health
│   └── test/SKILL.md            # /test — guided manual testing loop
├── agents/
│   └── story-reviewer.md        # Review stories against acceptance criteria
├── templates/                   # Scaffolded by /init
│   ├── scripts/ralph/
│   │   ├── prompt.md            # Ralph agent instructions
│   │   └── prd.json.example     # Example sprint format
│   ├── docs/
│   │   ├── tech-debt.md         # Tech debt tracking template
│   │   ├── testing/
│   │   │   └── issues.md        # Bug tracking template
│   │   └── ideas/
│   │       └── _index.md        # Ideas index template
│   └── RALPH.md                 # Project-level configuration
├── README.md                    # Install guide, skill reference, credits
├── LICENSE                      # MIT (with snarktank attribution)
├── CHANGELOG.md
└── package.json                 # For npm publishing
```

---

## 4. Project Configuration: RALPH.md

Each project that uses ralph-cc has a `RALPH.md` in its root. This file replaces hardcoded project-specific references in skills. Skills read `RALPH.md` to know what commands to run, where docs live, and how the project is structured.

Created by `/init` during setup.

```markdown
# RALPH.md

## Project
Name: [Project name]
Description: [One-line description]
Type: [product | feature]

## Quality Commands
typecheck: [e.g., npm run typecheck]
lint: [e.g., npm run lint]
test: [e.g., npm test]
e2e: [e.g., npm run test:e2e — optional]
e2e_single: [e.g., bash scripts/test-e2e.sh {flow} — optional]

## Documents
prd: docs/PRD.md
backlog: docs/POST_MVP_IMPROVEMENTS.md
design: [e.g., docs/DESIGN_PRINCIPLES.md — optional]
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

Skills reference these values instead of hardcoding paths or commands. For example, the ralph agent reads `Quality Commands` to know what checks to run, and `/new-sprint` reads `Documents.prd` to find the PRD.

---

## 5. Skills

### 5.1 /init — Project Scaffolding

**Purpose:** Set up ralph-cc in a new project directory.

**Flow:**

1. Check if ralph is already initialized (look for `RALPH.md`)
2. If already initialized, show current config and offer to reconfigure
3. Scaffold directory structure:
   - `scripts/ralph/prompt.md` — ralph agent instructions
   - `scripts/ralph/prd.json.example` — example sprint format
   - `docs/tech-debt.md` — empty template
   - `docs/testing/issues.md` — empty template
   - `docs/ideas/_index.md` — empty template
4. Ask setup questions:
   - "What's your project name?"
   - "What's your typecheck command?" (scan package.json / Makefile / pyproject.toml for hints)
   - "What's your lint command?"
   - "What's your test command?"
   - "Do you have an E2E test setup?" (optional)
5. Write `RALPH.md` with answers
6. If a `CLAUDE.md` exists, append a ralph section pointing to `RALPH.md`
7. Show next steps: "Run `/prd-plan` to define your product requirements, then `/new-sprint` to create your first sprint."

**Does NOT create a PRD.** That's `/prd-plan`'s job. `/init` saves the project name and type to `RALPH.md`, which `/prd-plan` reads to avoid re-asking. `/prd-plan` should always check `RALPH.md` for existing context before starting its conversation.

**E2E testing rules:** E2E tests are always optional. They only run if configured in `RALPH.md` (the `e2e` and `e2e_single` fields). If not configured, skills skip E2E references entirely — no `testFlow` field in stories, no E2E step in quality checks. If configured, the ralph agent runs E2E for stories that have a `testFlow` value.

### 5.2 /prd-plan — Product Requirements Planning

**Purpose:** Create or audit the full product requirements document. This is the master document that all sprints trace back to.

**Gate:** `/init` must have been run first (RALPH.md must exist).

**Flow — first question:**

"What are you planning?"
1. **A new product from scratch** → full walkthrough
2. **A new feature for an existing project** → lighter walkthrough, scan codebase for context
3. **I have a PRD already** → audit and reformat

#### Path 1: New product from scratch

Deep structured conversation:

1. **Vision** — What are you building? What problem does it solve? Why does this need to exist?
2. **Users** — Who are the target users? What are their goals and pain points? (Define 1-3 personas)
3. **Core features** — What are the main capabilities? Walk through each one.
4. **Scope** — What's v1 vs later? What are you explicitly NOT building? (Non-goals)
5. **Data model** — What are the key entities and their relationships?
6. **Tech stack** — What are you building with? (Or scan existing codebase)
7. **Success criteria** — How will you know the product is working?

Generate `docs/PRD.md` with standardized sections:
- Overview / Vision
- Target Users / Personas
- Features (numbered sections, each with requirements)
- Data Model
- Tech Stack
- Non-Goals
- Open Questions

#### Path 2: New feature for existing project

Lighter conversation — most context already exists:

1. Scan codebase to understand existing structure, stack, patterns
2. Read existing CLAUDE.md / AGENTS.md / README for context
3. **What feature are you adding?** What does it do? Who benefits?
4. **Scope** — What's included, what's not?
5. **Technical approach** — New tables? New screens? API changes?
6. **Dependencies** — What existing code does this build on?

Generate `docs/PRD.md` (or append a feature section to existing PRD) with the same structure, scaled down.

#### Path 3: Audit existing PRD

Read the provided PRD and check completeness:

- Does it define the problem/vision? → if not, ask
- Does it identify users/personas? → if not, ask
- Does it list features with enough detail to generate stories? → if not, walk through gaps
- Does it define scope boundaries (non-goals)? → if not, ask
- Does it cover the data model? → if not, ask
- Are features prioritized (v1 vs later)? → if not, ask

Walk through each gap one at a time. Then rewrite into ralph's standard format.

**Output:** `docs/PRD.md` in standardized format, path saved to `RALPH.md` Documents section.

### 5.3 /new-sprint — Sprint Generation

**Purpose:** Pick a chunk of work from the PRD or backlog and generate `scripts/ralph/prd.json` with user stories.

**Gate:** PRD must exist (checks `RALPH.md` Documents.prd path). If missing, refuses and points to `/prd-plan`.

**Generalized from closetize's `/new-prd`.** Key changes:
- Reads PRD path from `RALPH.md` instead of hardcoded closetize doc
- Reads backlog path from `RALPH.md` instead of hardcoded POST_MVP_IMPROVEMENTS.md
- Quality commands come from `RALPH.md` instead of hardcoded `npm run typecheck`
- No closetize-specific PRD section references (4.1-4.7)

**Flow:**

1. Read PRD, backlog (if exists), tech debt (if exists), archived sprints
2. Build a map of what's done vs what's available
3. Present sources to user with recommendations, using this priority order:
   - Any feature marked v1/MVP in PRD that's incomplete (highest priority)
   - High-priority items from the backlog
   - High-severity tech debt items (Medium/Large effort)
   - Other backlog items
   - User can always override and pick something else
4. User picks what to build next
5. Archive current sprint if one exists:
   - If the current `prd.json` has incomplete stories, warn: "This sprint has [N] incomplete stories. Archive anyway?"
   - If user confirms (or all stories are complete), copy `prd.json` and `progress.txt` to `scripts/ralph/archive/[date]-[feature]/`. The `[feature]` is derived from `prd.json.branchName` with the `ralph/` prefix stripped (e.g., `ralph/user-auth` → `user-auth`). If the directory already exists, append a counter (e.g., `user-auth-2`).
   - If user declines, return without archiving
6. Explore codebase for relevant patterns and files
7. Generate stories following rules:
   - Ordered by dependency (schema → backend → UI → integration)
   - Each story fits one context window (~30-60 min)
   - Acceptance criteria are specific and verifiable
   - Quality command from `RALPH.md` included in every story
   - 5-8 stories per sprint
8. Review with user, adjust, write `scripts/ralph/prd.json`

**prd.json metadata:** Each sprint includes a `source` field indicating where the work came from (e.g., `"source": "prd"`, `"source": "backlog"`, `"source": "tech-debt"`) and a `sourceItem` identifying which specific PRD feature, backlog item number, or tech debt ID it maps to. This tells `/start` Case D which item to mark as complete when the sprint merges.

### 5.4 /start — Session Dispatcher

**Purpose:** First thing to run in any session. Reads project state, shows what's going on, picks up where last session left off.

**Generalized from closetize's `/start`.** Key changes:
- Quality commands from `RALPH.md`
- Doc paths from `RALPH.md`
- No closetize-specific references (Maestro, Expo, etc.)
- E2E testing only referenced if configured in `RALPH.md`

**Cases (evaluated in order, first match wins):**
- A: Uncommitted changes exist (any branch) → help commit or continue
- B: Active sprint with WIP commit (any branch) → pick up interrupted story. Story ID parsed from `wip: [STORY-ID] - [description]` commit message format.
- C: Active sprint with incomplete stories (any branch) → continue next story. If current branch doesn't match `prd.json.branchName`, checks out the correct branch.
- D: All stories complete, still on ralph branch (not merged) → review + merge flow
- E: On main, no active sprint (prd.json doesn't exist or is fully merged) → suggest `/new-sprint`
- F: Active test plan in progress → offer to continue testing. If both a sprint and test plan exist, ask which to work on.
- G: Unexpected state (unknown branch, corrupted prd.json, etc.) → show current branch, git status, and prd.json summary. Offer options: switch to main, re-run `/init`, or describe what they'd like to do.

**RALPH.md validation:** On every invocation, `/start` validates that `RALPH.md` exists and has required fields (Project, Quality Commands, Documents.prd). If missing or incomplete, shows what's wrong and offers to re-run `/init` or fill gaps interactively.

When ready to work, loads context and executes the Ralph loop: pick story → explore code → implement → quality checks → commit → update PRD → log progress → stop for review.

### 5.5 /ralph — Sprint Dashboard

**Purpose:** Quick status check. Shows sprint progress table and a kickoff prompt for copy-pasting into a fresh session.

Lightweight — no state assessment, no working. Just dashboard + prompt.

Generalized: no project-specific references.

### 5.6 /wrap — Session Handoff

**Purpose:** Clean handoff when ending a session. Commits WIP, logs progress, summarizes for next agent.

**Generalized from closetize's `/wrap`.** Key changes:
- Quality commands from `RALPH.md`
- Detects active workflow (dev sprint or testing) and follows appropriate handoff

**Flow:**
1. Detect active workflow: check `test-plan.json` (testing) and `prd.json` (dev sprint)
2. Check git status, diff
3. Commit WIP if uncommitted changes exist:
   - Dev sprint: `wip: [STORY-ID] - [description]`
   - Testing: `wip: testing - [TC-ID] - [description]`
4. Log handoff notes:
   - Dev sprint → append to `progress.txt` (what was done on the story, what remains, typecheck status, files modified, notes for next agent)
   - Testing → append to `test-progress.txt` (tests run, results, blockers fixed, issues logged, next test case)
5. Show summary with next steps

### 5.7 /log — Quick Capture

**Purpose:** Capture bugs or improvements mid-session without interrupting flow.

**Generalized from closetize's `/log`.** Key changes:
- File paths read from `RALPH.md` Documents section
- No closetize-specific feature references
- Creates target files from templates if they don't exist

**Flow:**
1. Parse input (bug vs improvement)
2. Ask 1-2 clarifying questions
3. Route to correct file (issues.md for bugs, backlog for improvements)
4. Recommend fix now vs later
5. Confirm and return to work

### 5.8 /new-idea — Brainstorm & Research Ideas

**Purpose:** Structured brainstorming for new feature ideas. Produces a living document in `docs/ideas/` that can be promoted to the backlog.

**Generalized from closetize's `/new-idea`.** Key changes:
- Reads project context from `RALPH.md` and PRD instead of closetize-specific docs
- Market research uses generic web search (no fashion-specific framing)
- Codebase audit is project-agnostic

**Flow:**
1. Explore the idea (problem, vision, who benefits, inspiration)
2. Research the market (competitors, adjacent solutions, technical approaches)
3. Audit the codebase (what exists, what's needed)
4. Assess (value, effort, risk, scope creep, market fit)
5. Document in `docs/ideas/[idea-name].md`
6. Update index
7. Offer to promote to backlog or save for later

### 5.9 /promote-idea — Move Idea to Backlog

**Purpose:** Promote a researched idea from `docs/ideas/` into the backlog, resolving open questions along the way.

**Generalized from closetize's `/promote-idea`.** Key changes:
- Backlog path from `RALPH.md`
- No closetize-specific format references

**Flow:**
1. Show all ideas sorted by readiness
2. User picks one
3. Walk through open questions one by one
4. Write backlog entry with decided approach
5. Update idea status to "planned"

### 5.10 /tech-debt-review — Assess Tech Debt

**Purpose:** Prevent tech debt from silently accumulating. Reviews `docs/tech-debt.md` at key milestones.

Already generic — no changes needed from closetize version beyond reading file path from `RALPH.md`.

### 5.11 /test — Manual Testing Loop

**Purpose:** Guide the user through structured manual test cases on their device.

Already mostly generic. Key changes:
- Remove closetize-specific references (Expo Go, etc.)
- Test plan format stays the same (test-plan.json)

---

## 6. Agents

### 6.1 story-reviewer

**Purpose:** Reviews completed stories against acceptance criteria, project patterns, and code quality.

**Generalized from closetize's story-reviewer.** Key changes:
- Reads project patterns from `CLAUDE.md` / `AGENTS.md` (whatever exists)
- Design principles check only if a design doc is configured in `RALPH.md`
- No closetize-specific pattern checks (Supabase, Expo Router, etc.)
- Quality command references from `RALPH.md`

---

## 7. Templates

Files scaffolded by `/init` into the project:

### scripts/ralph/prompt.md
The Ralph agent instructions. Generalized version of the execution loop:
- Read PRD, progress log
- Check correct branch
- Pick highest priority incomplete story
- Explore relevant code before implementing
- Implement single story
- Run quality checks (from RALPH.md)
- Commit, update PRD, log progress
- Update AGENTS.md with reusable patterns
- Stop after one story

### scripts/ralph/prd.json.example
Example sprint format:
```json
{
  "project": "MyApp",
  "source": "prd",
  "sourceItem": "4.1",
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
    }
  ]
}
```

### scripts/ralph/progress.txt
Initial structure (created empty, grows over time):
```
# Ralph Progress Log
Started: [date]

## Codebase Patterns
(Discovered patterns are consolidated here — always read this section first)

---
```

### scripts/ralph/test-plan.json (not scaffolded — created by /test when needed)
Structure for manual testing:
```json
{
  "name": "MVP Manual Testing",
  "branchName": "testing/mvp-round-1",
  "device": "e.g., iPhone 16 Pro / Chrome 130 / Android Pixel 9",
  "method": "e.g., Expo Go / localhost:3000 / physical device",
  "current": "TC-01",
  "testCases": [
    {
      "id": "TC-01",
      "title": "Fresh Signup",
      "feature": "Auth",
      "precondition": "No existing account",
      "steps": [
        "Open app — should see login screen",
        "Tap 'Sign Up' link",
        "Enter credentials",
        "Tap sign up button"
      ],
      "expected": "Account created, redirected to home",
      "passes": null,
      "notes": ""
    }
  ]
}
```
- `passes: null` — not yet tested
- `passes: true` — passed
- `passes: false` — failed (details in `notes` and `issues.md`)

### docs/tech-debt.md
Template with Active Items and Resolved Items sections.

### docs/testing/issues.md
Template with severity levels (Blocker, Major, Minor, Polish) and status values (Logged, Fixed, Deferred, Won't Fix).

### docs/ideas/_index.md
Empty index table for ideas.

### RALPH.md
Project configuration (see Section 4).

---

## 8. Workflow Diagram

```
/init                    Scaffold project files + RALPH.md
  │
  ▼
/prd-plan                Define or audit product requirements
  │                      (required before any sprint)
  ▼
/new-sprint              Pick feature → generate prd.json with stories
  │
  ▼
/start ──────────────── Session dispatcher (run every session)
  │                        │
  ▼                        ▼
Ralph loop               /wrap (end session cleanly)
  │ (one story            │
  │  per session)         ▼
  │                     /start (next session picks up)
  ▼
All stories done?
  │
  ├─ No → /start again
  │
  ├─ Yes → Review + merge
  │          │
  │          ▼
  │        /new-sprint (next feature)
  │
  ▼
Side workflows (anytime):
  /log              → capture bug/improvement
  /new-idea         → brainstorm feature idea
  /promote-idea     → move idea to backlog
  /tech-debt-review → assess debt health
  /test             → manual testing loop
  /ralph            → quick sprint dashboard
```

---

## 9. Generalization Strategy

Every skill that exists in the closetize app needs these changes to become generic:

1. **Replace hardcoded paths** with `RALPH.md` lookups
2. **Replace hardcoded commands** (npm run typecheck, Maestro, etc.) with `RALPH.md` Quality Commands
3. **Remove project-specific references** (Supabase, Expo Router, design tokens, etc.)
4. **Remove project-specific PRD section numbers** (4.1-4.7) — use generic feature detection
5. **Make E2E testing optional** — only referenced if configured in `RALPH.md`
6. **Make design principles optional** — only checked if a design doc path exists in `RALPH.md`

The core workflow logic (state machine in /start, story execution loop, handoff protocol, sprint generation) remains identical.

---

## 10. Naming & Branding

- **Package name:** ralph-cc
- **npm:** ralph-cc (available)
- **GitHub:** `<owner>/ralph-cc`
- **License:** MIT (include snarktank copyright notice)
- **Credits in README:** Based on snarktank/ralph and Geoffrey Huntley's Ralph pattern

---

## 11. What's NOT in v1

- Multi-runtime support (Gemini CLI, Codex, OpenCode) — Claude Code only for now
- Parallel story execution (sub-agents) — kept sequential for simplicity
- GUI/dashboard — terminal only
- Custom skill authoring — users can add their own skills to `.claude/skills/` but ralph-cc doesn't provide tooling for that
- CI/CD integration
- Team collaboration features
