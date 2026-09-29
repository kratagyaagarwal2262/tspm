# Codex agent routing for TSPM

The project default for new local tasks is Luna at medium effort. A skill supplies the workflow; a custom agent supplies the model and reasoning effort for delegated work. Invoking a skill does not change the parent task's model. A model explicitly selected in the Codex composer takes precedence over the project default.

Delegate when a task has a substantial, bounded part with stable inputs. Keep a small edit in the parent task. Pass the relevant spec, acceptance criteria, affected paths, and allowed files to each agent. The parent integrates the result and reports what was actually verified. Avoid concurrent edits to the same files.

| Work | Agent | Model / effort | Typical skill |
|---|---|---|---|
| Read-only file discovery and codebase mapping | `tspm_explorer` | Luna / low | `$flutter-explain` |
| Product architecture and cross-feature decisions | `tspm_architect` | Sol / high | `$flutter-plan-change`, `$to-spec` |
| Weight, energy, confidence, and other calculation methodology | `tspm_analytics` | Astra / medium | `$to-spec`, calculation review |
| Settled feature models, repositories, and BLoC/state code | `tspm_feature_engineer` | Luna / medium | `$flutter-create-feature-e2e`, `$flutter-create-screen-e2e` |
| Screen hierarchy, visual implementation, and chart presentation | `tspm_ui_engineer` | Sol / medium | `$flutter-design`, `$flutter-create-screen` |
| Scoped tests from settled behavior | `tspm_test_engineer` | Luna / medium | `$flutter-write-tests` |
| Independent convention or spec review | `tspm_reviewer` | Sol / high | `$flutter-code-review` |

For an end-to-end skill, finish and settle its planning tables before delegation. Give each agent one owned phase or file set. When reviewing, run the convention and spec axes independently, even if they use the same reviewer role. Use `tspm_analytics` for a separate methodology check only when a change makes a quantitative interpretation or health-related claim.

These roles adapt the useful layer ownership from Limomate's Claude agents. They do not import Limomate's Flutter sizing, fixtures, API, or store-release conventions. The actual `tspm` stack is in `docs/agents/project.md`; the confirmed product scope is in `docs/specs/tspm-product-plan.md` and the draft background in `docs/specs/product-vision.md`.
