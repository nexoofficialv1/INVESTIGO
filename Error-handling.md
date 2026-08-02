# INVESTIGO Error Handling

## Principles
- Never fail silently.
- Never discard a saved draft because preview/export failed.
- Show a clear Bengali/English message, recovery action and retry option.
- Log technical details without exposing case data.

## Required patterns

### Local storage
- Catch JSON decode and model migration errors.
- Keep the original raw backup before repair/migration.
- Show which record could not be loaded.
- Do not overwrite valid data with an empty list after a read failure.

### PDF/DOC generation
- Use bounded generation time and visible progress.
- Long CD content must be split into page-safe rows/chunks.
- A `PdfTooBigPageException` or timeout must show Retry/Edit, not an endless spinner.
- Preview, PDF and DOC must use the same saved entry source.
- Export failure must not alter approval or saved-draft status.

### Narration parsing
- Empty/unsupported narration returns an editable warning, not fabricated entries.
- Missing time/place/name remains explicitly missing.
- Duplicate/one-time action requires confirmation or justification.
- Parser exceptions must preserve the original narration.

### Voice input
- Handle microphone permission denied, unavailable speech service, no speech detected and interrupted listening.
- Always allow manual typing as fallback.

### Forms and validation
- Required fields are validated before approval/export.
- Validation messages identify the exact field/document.
- Template overflow must use continuation pages, never silently shrink or change official columns.

### Network/backend
- Network features are optional. Timeout, offline, authentication and server errors must not block local work.
- Retry must be explicit; no repeated background submission of sensitive data.

### CI and release
A release is blocked by compile errors, failed tests, missing documentation files, missing APK artifacts, or an unreviewed schema migration.

## Known high-risk areas
- CD multi-page pagination.
- Bengali font shaping and line breaks.
- Landscape NCR/Dead Body Challan print scaling.
- DOC renderer differences between Word-compatible applications.
- Backward compatibility of JSON records.

## Change rule
Every user-visible failure mode, recovery path, fallback, retry, timeout, migration failure or known issue must be recorded here and covered by a test where practical.
