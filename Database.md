# INVESTIGO Database

## Current persistence
The first release stores JSON records locally through `LocalStoreService`. Typed domain facades restrict which records each screen can access.

## Regular Case Investigation aggregate
Primary root: `CaseFile`
Related collections:
- `CdEntry`
- `PendingCdAction`
- `InvestigationAction`
- `StatementEntry`
- `SketchMapEntry`
- final-document drafts and approval states

Shared identifiers: `caseId` / case record `id`.

## UD aggregate
Primary root: `UdCase`
Fields cover deceased identity, informant, identifier, body description, injuries, discharge observations, PO, articles, probable cause, witnesses and narrative.

The same UD record supplies Inquest, Surathal, Form 5371, PM requisition and Form 5370. It is not joined to a regular case record.

## NCR aggregate
Primary root: `NcrReport`
Stores NCR reference, complainant/information, accused, arrest/hearing details, offence narrative, witnesses, result and remarks.

## Migration rules
- New fields must have safe defaults.
- `fromJson` must accept older records with missing keys.
- Existing storage keys must not be renamed without a migration.
- Cross-domain copying is forbidden except explicit user-created references.

## Future server mapping
PostgreSQL is deferred. When introduced, separate tables/schemas will preserve the three domain boundaries and use UUIDs plus audit timestamps.

## Sketch map object compatibility
`SketchMapObject.type` remains a string enum name. New values are additive and old saved values remain readable. Geometry fields remain normalized doubles.

## Regular Case final-document projection (v1.7.2)

`RegularCaseDocumentData` is a runtime projection, not a new UD/NCR table. It
combines only records linked by the same regular `caseId`:

- `CaseFile`
- `CdEntry[]`
- `StatementEntry[]`
- investigation summary
- accused-status summary
- relied-document summary
- result communication

Final CD, Charge Sheet and IF-5 approvals must be stored independently. A
future migration must use separate keys such as `final_cd_<caseId>`,
`charge_sheet_<caseId>` and `if5_<caseId>` so approving one document does not
implicitly approve the other two.

## Final-document local records (v1)
- `final_cd_drafts_v1`: map keyed by regular `caseId`.
- `charge_sheet_drafts_v1`: map keyed by regular `caseId`.
- `if5_drafts_v1`: map keyed by regular `caseId`.
Each record stores editable content, independent approval state and `updatedAt`.

## Final-document draft additions (v1.7.4)
`FinalCdDraft` stores entry time, place and synopsis. `If5Draft` stores charge-sheet number/date, original/supplementary status, I.O. particulars, uncharged accused, laboratory result, false-case action and dispatch details. Missing legacy JSON keys receive safe defaults.


## v1.7.6
No database schema change. RC-1 feature scope is static application metadata and is not stored with case, UD or NCR records.

## Officer profile v2 fields
Added PS address, PIN, CUG, WhatsApp, default hospital, morgue, FSL office and supervisory office. JSON loading remains backward compatible.

## v185
No schema change. FSL/A Form remain Regular Case domain documents and bind to Officer Profile plus selected Case data.

## Profile binding rule

Officer Profile is the authoritative source for Police Station and District during UD/NCR save and export. Loaded legacy drafts may contain older station values, but the current profile values replace them when a document is collected for saving or generation. No schema migration is required because existing JSON keys remain unchanged.

## RC-1 v189
No database migration is required. Existing `CdEntry.tableLines` records remain backward compatible; this update changes rendering only.

## v193 data-flow note

No duplicate UD document database was introduced. Auto-filled narration values are saved into the existing `UdCase` record, which remains the single source for Inquest/Surathal, Dead Body Challan and UD Final Report. Statement and CD source text remains unchanged in storage; target-language text is generated during preview/export.

## v194 Data Impact

No schema or migration change. Preview/export reads the saved CD and Statement records.

<!-- v195-desktop-foundation -->
## v195 desktop storage

The desktop foundation retains the existing SharedPreferences keys and JSON
model contracts. This prevents model drift between mobile and desktop and keeps
backup import/export compatible. PostgreSQL remains an integration target;
v195 does not silently migrate local records or introduce a second schema.
