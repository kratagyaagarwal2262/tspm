---
name: writing-for-agents
description: Write concise Codex project instructions and skills that trigger reliably without overloading every task.
---

# Writing for agents

Use this when editing `AGENTS.md` or a skill in `.agents/skills/`.

## Keep instructions useful

- Put repository-wide rules that matter across tasks in `AGENTS.md`; keep it short because Codex reads it for repository work.
- Put a repeatable workflow in one skill. Keep supporting examples, templates, and checklists in separate files linked from that skill.
- Make a skill's `description` state what it does and when Codex should use it. Use only `name` and `description` in `SKILL.md` front matter.
- For workflows that should start only when a person requests them, add `agents/openai.yaml` with `policy.allow_implicit_invocation: false` and a `default_prompt` that uses `$skill-name`.
- Refer to another skill by invoking it as `$skill-name`; don't say to call a Claude or opencode Skill tool.
- Point to project facts in `docs/agents/project.md` instead of repeating them across skills.

## Before finishing

- Check that instructions match the files and commands in this project.
- Remove product-specific assumptions from reusable skills.
- Keep user instructions and this repository's actual code authoritative when they conflict with a generic convention.
