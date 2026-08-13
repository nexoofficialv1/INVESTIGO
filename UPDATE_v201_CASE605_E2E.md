# INVESTIGO v201 — Case 605 E2E + Road Traffic Accident Adaptive Workflow

## What the Case 605 test exposed and fixed
- Added Road Traffic Accident case classification (including BNS 281 / RTA keywords).
- CD-II now suggests road-accident-specific pending work: witness examination, Injury Report/BHT/medical papers, and offending vehicle/actual driver verification.
- Added dedicated medical-paper workflow with Departure -> Hospital Arrival -> Requisition/Collection chronology.
- Added dedicated offending vehicle/driver verification workflow.
- CD-I complainant examination now records its own place; it no longer incorrectly inherits the first field-arrival place.
- Added “PO is first investigation destination?” question. If Yes, DD/DA are reused for PO departure/arrival so the officer does not enter the same times twice.
- Added validation that First Arrival Place must match Exact PO when PO is declared the first destination.
- Fixed completed-action inference so complainant u/s 180 statement alone does not falsely mark all witness examination as completed.
- Added end-to-end regression fixture for Kalna PS Case No. 605/2026.

## Demo boundary note
The E2E test uses explicitly labelled demo N/S/E/W values only to exercise auto-sketch generation. They are not treated as real Case 605 facts.

## Verify in Termux
```bash
flutter analyze
flutter test test/cd_case_605_e2e_test.dart
flutter test
```

## Chronology refinements from the E2E run
- CD-I PO clue search, local witness enquiry, departure from PO, and PS return are separate timed marginal entries.
- Medical-paper follow-up has a full travel chain: PS departure -> Hospital arrival -> requisition/collection -> Hospital departure -> PS return.
- If PO is the first investigation destination, DD/DA are reused and the app auto-syncs First Arrival Place from Exact PO.
- Complainant examination place defaults to the officer's PS but remains editable.
- Continuation closing does not fabricate a second return-to-PS event when the last action already occurred at the PS.
