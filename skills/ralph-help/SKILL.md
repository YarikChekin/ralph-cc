---
name: ralph-help
description: Quick reference for all ralph-cc commands — show this when the user asks for help, what commands are available, or how ralph works
disable-model-invocation: true
---

# /ralph-help — Quick Reference

Show the user this cheat sheet:

```
## ralph-cc Commands

### Setup (run once per project)
  /ralph-init     Scaffold ralph into your project
  /prd-plan       Create or audit your product requirements doc

### Sprint Workflow (the core loop)
  /new-sprint     Generate the next sprint from your PRD or backlog
  /start          Begin a session — picks up where you left off
  /wrap           End a session cleanly — commits WIP, logs progress
  /ralph          Quick sprint status dashboard

### Anytime
  /log            Quick-capture a bug or improvement mid-session
  /new-idea       Brainstorm and research a feature idea
  /promote-idea   Move a researched idea into the backlog
  /tech-debt-review  Assess tech debt health
  /test           Guided manual testing loop

### Tips
  - Run /start at the beginning of every session
  - Run /wrap before ending a session or when context is getting large
  - The typical flow: /ralph-init → /prd-plan → /new-sprint → /start
```

Then stop. Do not offer further suggestions or start working — just show the reference.
