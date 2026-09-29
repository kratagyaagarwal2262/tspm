# tspm

Tracking Super Pro Max. Helps you track weight but not like olden days. It's way more detailed. Trust me

## Development

```sh
flutter pub get
flutter run
dart format .
flutter analyze
flutter test
```

## Codex and engineering conventions

Project guidance is in [AGENTS.md](AGENTS.md). The Flutter Engineering Kit skills are installed under `.agents/skills/`; use `$ask-kit` to choose a workflow. Project-specific architecture, platform, and verification facts are recorded in [docs/agents/project.md](docs/agents/project.md).

The project is currently Android-only. The secure-storage baseline requires Android API 23 or newer.
