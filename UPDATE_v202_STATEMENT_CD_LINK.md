# INVESTIGO v202 — Statement ↔ CD Auto-Link

## Goal
Officer যেন একই facts দ্বিতীয়বার type না করেন। CD workflow-এ statement record করার সময় যে data দেওয়া হবে, সেই data থেকেই separate u/s 180 BNSS Statement sheet save হবে এবং CD-তে শুধু official statement-recording mention থাকবে।

## Implemented

### CD-I — Complainant
- Complainant examined? Yes/No
- Examination time and place
- Statement-header identity/address details
- Statement u/s 180 BNSS recorded? Yes/No
- If Yes: exact statement body, in witness's own words / first-person narrative
- Generate CD করলে linked StatementEntry automatic save হয়
- CD narration statement body repeat করে না

### CD-I — Victim/VG (POCSO/Sexual offence cases)
- Victim/VG name
- Identity/address for statement header
- Examination/contact time and place
- Factual examination/non-cooperation note
- Separate statement recorded? Yes/No
- If Yes: exact statement body
- Linked StatementEntry automatic save

### CD-II onward — Witness Examination
Structured fields:
- Witness name
- Identity/address
- Role/category (Eye/Seizure/Local/Police witness etc.)
- Statement recorded? Yes/No
- If Yes: exact u/s 180 statement body

CD only says the witness was examined and statement recorded. The statement body is not duplicated inside the Case Diary.

### CD-II onward — Victim/VG
Same linked-statement mechanism as above.

## Safety / Consistency Rules
- `Statement recorded = No` => no Statement sheet is invented.
- `Statement recorded = Yes` + blank statement body => validation error.
- Missing identity/address => warning, because the statement header would be incomplete.
- Generated statements carry source metadata: Case ID, CD number, action ID, date/time/place, recording officer.
- Re-sync of the same CD replaces the generated statement(s) for that CD instead of silently duplicating them.
- Old manually created StatementEntry JSON remains backward-compatible; new linkage fields default safely.

## Case 605 regression
Kalna PS Case No. 605/2026 CD-I test now verifies:
1. Complainant examination creates the CD marginal entry.
2. The exact statement body is NOT repeated in the CD narration.
3. The same input creates one linked u/s 180 BNSS statement for Subhankar Biswas.
4. Source CD number and linkage metadata are retained.

## Tests added
- `test/statement_link_service_test.dart`
- `test/linked_statement_store_service_test.dart`
- Case 605 E2E test extended for Statement ↔ CD linkage.

## Important scope note
v202 links one structured primary witness per `Witness Examination` action. Existing free-text `cd1_police_witnesses` is not auto-split into multiple statement sheets because parsing a free-text list could create incorrect witness identities. A repeatable multi-witness statement row UI should be the next enhancement for cases where several witnesses are examined in the same CD.

## u/s 180 Statement Output Correction
The old INVESTIGO Statement PDF/DOC template showed a maker/witness Signature/LTI/RTI field. v202 removes that field from u/s 180 BNSS statement output and keeps the `Recorded by` officer block only. Linked statements also print Source CD, recorded date, time and place when those values are available.

This also matches the supplied police statement samples used for the CD workflow: the statement sheet ends with the recording-officer block rather than a witness-signature block.

## Save consistency
- Linked statement sheets are synchronised before committing a newly generated CD.
- If the CD save itself fails, the just-generated linked statement set for that uncommitted CD number is removed on a best-effort rollback.
- Failure to mark a separate pending form/requisition as consumed does not delete an already-saved CD or statement; the UI reports that secondary failure.

## Additional contract test
- `test/statement_180_output_contract_test.dart`
  - verifies PDF and DOC u/s 180 output no longer contains a witness Signature/LTI/RTI field;
  - verifies the recording-officer block and linked source metadata hooks remain present.
