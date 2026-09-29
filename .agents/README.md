# Flutter Engineering Kit for Codex

This project contains a local Codex adaptation of [flutter-engineering-kit](https://github.com/kratagyaagarwaldots/flutter-engineering-kit), based on source commit `f85236d` from the checkout available during installation.

- Skills live in `.agents/skills/` and follow the Codex skill layout.
- The Flutter and general product-engineering tracks are included. FastAPI and OpenAPI backend skills are excluded.
- Templates are in `.agents/template/` for kit workflows that reference them.
- Kit-owned Claude Code and opencode hooks, agents, and generated mirrors are not installed here.
- Project-specific Codex agents and model settings live in `.codex/`; see `docs/agents/agent-routing.md` for their scope and the skills that use them.
- This is a local snapshot. To update it, review a newer upstream version and reapply the Codex adaptations; do not run the kit's Claude, Cursor, or opencode sync scripts on this project.

The upstream kit is licensed under the included `FLUTTER-ENGINEERING-KIT-LICENSE`.
