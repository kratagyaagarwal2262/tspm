# Store and compliance document conventions

Use these conventions for files under `docs/store/`.

- Do not invent bundle IDs, URLs, contacts, company names, prices, dates, or business facts. Use `TODO` with an owner when the information is missing.
- Keep source traceability in `_GENERATION_REPORT.md`, not in client-facing documents.
- Never include secrets. Report whether a secret exists and how it is handled.
- Show store character limits and counts for constrained fields.
- Cite the relevant Apple App Review or Google Play policy section for compliance claims; use `TODO (policy unfetched)` until the policy is checked.
- Keep law, contact details, and URLs consistent across documents. Omit sections for features the app does not have.
- Write in plain professional prose for clients, lawyers, and reviewers. Do not put code, repository paths, manifest keys, package names, versions, or build commands in client documents.
- Keep technical evidence and source files in `_GENERATION_REPORT.md`.
- Use clear headings, numbered legal sections, and tables for reference material. Finish each document with one `Still needed / TODO` table.
- Use standard Markdown that prints cleanly to PDF.
