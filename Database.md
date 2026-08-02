# INVESTIGO Database

## Current storage
The current application is offline-first and uses `SharedPreferences` JSON through `LocalStoreService`.

## Current keys
| Key | Model/use |
|---|---|
| `officer_profile_v1` | Officer profile |
| `cases_v1` | Case master records |
| `cd_entries_v1` | Daily CD documents |
| `statement_entries_v1` | Witness/statement records |
| `form_notice_entries_v1` | Notice/form drafts |
| `pending_cd_actions_v1` | Assistant-approved pending CD rows |
| `sketch_maps_v1` | Sketch Map records |
| `backend_config_v1` | Optional backend configuration |
| `ud_cases_v1` | UD case records |
| `investigation_actions_v1` | Investigation action register |
| `ncr_reports_v1` | NCR drafts |

## Data principles
- Every record must have a stable ID.
- Case-related records must store `caseId`/`udCaseId` rather than duplicate the full case.
- User-entered facts and generated draft text must remain distinguishable.
- Approval status, created/updated timestamps, and source (manual/assistant/imported) should be stored for final documents.
- One-time versus repeatable actions must be represented by rule metadata, not inferred only from display text.

## Current limitations
`SharedPreferences` is not transactional, is unsuitable for large document collections, and has limited migration/query support. It is acceptable only for prototype/early field testing.

## Required pre-production migration
Move structured data to a local transactional database such as SQLite/Drift or Isar before broad deployment. Required entities:
- officers
- cases
- ud_cases
- ncr_reports
- cd_documents
- cd_rows
- investigation_actions
- statements
- sketch_maps
- sketch_objects
- indexes
- official_document_drafts
- reminders
- audit_events
- migrations

## Migration policy
- Never delete an existing key during a migration before verified import.
- Keep backward-compatible `fromJson` defaults.
- Create a backup before migration.
- Store schema version and migration result.
- Failed migration must leave the previous data readable.

## Future server database
PostgreSQL/server sync is deferred. No production case data should be sent to the current sample backend without a separate security and deployment review.

## Change rule
Any model field, storage key, relationship, migration, retention, or backup change must update this file in the same commit.
