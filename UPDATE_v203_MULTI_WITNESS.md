# INVESTIGO v203 — Multi-Witness Statement Workflow

## Goal
A single CD may contain examination of several witnesses. Officer enters each witness once; INVESTIGO generates the correct CD mention and, when marked recorded, a separate u/s 180 BNSS statement sheet for that witness.

## Workflow
1. Officer selects `Witness examination / u/s 180 BNSS statement` in a continuation CD, or uses the optional witness repeater in CD-I.
2. Tap `+ Add Witness`.
3. Enter witness name, identity/address, role/category, examination time, examination place, whether u/s 180 BNSS statement was recorded, the exact statement body, and optional examination note.
4. Add as many witnesses as required.
5. Choose one of two CD presentation modes:
   - **Separate Timed Entries** — one marginal CD line per witness, sorted by examination time.
   - **Grouped Same-Session Entry** — one marginal CD line listing all witnesses; each recorded statement still becomes a separate statement sheet.
6. Officer reviews the auto-linked statement preview and generates the CD.

## Legal/drafting guardrails
- The app never creates a statement sheet when `Statement recorded = No`.
- Statement body is not repeated in the CD. CD only records that the witness was examined and the statement was recorded in a separate sheet.
- Grouped Same-Session mode requires the same time and place for every witness in that batch.
- Duplicate witness names produce a warning for officer review.
- Witness examination time cannot be after CD closing time; in CD-I it also cannot precede FIR/complaint receipt time.
- Identity/address omission is a warning when a statement sheet is being created.
- Existing pre-v203 single-witness saved drafts remain readable through compatibility fallback.

## CD-I correction
The old `cd1_police_witnesses` field only asks who was present/associated with raid/search/seizure. v202 wording could incorrectly imply that statements had been recorded. v203 removes that inference. Statement recording is now represented only through the structured multi-witness repeater.

## Data model
New file: `lib/models/witness_examination_entry.dart`

- `WitnessExaminationEntry`
  - id
  - witnessName
  - witnessDetails
  - role
  - recordedTime
  - recordedPlace
  - statementRecorded
  - statementBody
  - examinationNote
- `MultiWitnessBatch`
  - mode: `separate` / `groupedSameSession`
  - entries[]
  - JSON encode/decode for storage in the existing CD answer map.

## Integration points
- `cd_workflow.dart`: new `CdQuestionType.witnessRepeater`.
- `cd_workflow_service.dart`: replaces fixed single-witness continuation questions with the repeater; adds optional CD-I repeater.
- `cd_builder_screen.dart`: Add/Edit/Delete Witness UI, common role chips, time picker, mode selector, copy-first-session helper.
- `cd_workflow_draft_service.dart`: creates separate or grouped CD marginal entries without repeating statement bodies.
- `statement_link_service.dart`: creates one linked `StatementEntry` per recorded witness using stable per-witness source IDs.
- `cd_workflow_validation_service.dart`: validates witness completeness, grouped session consistency, duplicates, and chronology.

## Tests
New: `test/multi_witness_workflow_test.dart`

Covers:
- repeater replaces fixed single witness UI contract,
- multi-witness JSON round trip,
- separate timed marginal entries,
- grouped same-session single CD line + multiple statement sheets,
- no fabricated statement when recording is marked No,
- grouped-session mismatch and closing-time validation.

## Next queued modules
- v204: Offline BNS/BNSS section search with authoritative enacted-law source/versioning and Bengali explanation layer.
- v205: English/Bengali BNSS forms library with case auto-fill and CD auto-link.
