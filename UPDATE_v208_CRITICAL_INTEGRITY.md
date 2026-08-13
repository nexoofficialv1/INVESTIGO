# INVESTIGO v208 — Critical Data Integrity & UD Lifecycle

## Locked UD lifecycle
1. UD Registration
2. Inquest / Surathal (Section 194 BNSS workflow label)
3. Dead Body Challan / PM Forwarding
4. Post Mortem Completed
5. PM Report Received
6. UD Final Form

### Chronology
- Inquest and Dead Body Challan are expected on the PM date or before it.
- Challan after planned PM date is blocked.
- Challan more than one day before planned PM date is allowed only after a visible officer confirmation warning.
- PM completion is recorded separately from PM report receipt.
- UD Final Form is blocked until PM report is received.
- If viscera/FSL/chemical/other report is marked pending, finalization is blocked.

### Integrity
The app does not infer:
- cause of death,
- foul play/no foul play,
- inquest completion,
- PM completion,
- PM report receipt,
- final enquiry result.

These require explicit officer input/confirmation.

## Case Entry fixes
- FIR/case facts only.
- Investigation-action questions removed from new case entry; those belong to CD Wizard.
- Required validation: PS Case No., case date, sections, PO, reporting date/time, FIR gist.
- Date/time selection uses pickers.
- Duplicate PS Case No. is blocked against another UUID.
- Existing legacy InvestigationStart data is preserved when editing an old case.

## Report fixes
- Dashboard opens general reports without silently binding the latest case.
- Case-linked Report is opened from Case Workspace.
- Templates no longer pre-assert PO visit, witness examination, document collection or other investigation acts.
- A report keeps a stable ID while repeatedly saving the same draft.
- v208 reports store structured workflow data and can be reopened from Saved Reports.

## Runtime validation still required
This patch package was built without a local Flutter SDK. Run `flutter analyze`, targeted tests, full tests, and an Android device round-trip before production use.
