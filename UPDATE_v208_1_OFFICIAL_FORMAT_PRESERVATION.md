# INVESTIGO v208.1 — Official UD Format Preservation Hotfix

This hotfix corrects the v208 document-layout regression without rolling back the v208 lifecycle or integrity gates.

## Locked principle

Workflow may change. Official document format must not.

The lifecycle remains:

`UD Registration → Inquest/Surathal → Dead Body Challan/PM Forwarding → PM Completed → PM Report Received → UD Final Form`

But the printable outputs are restored to the established INVESTIGO forms:

1. Detailed **INQUEST FORM** already used by INVESTIGO.
2. **West Bengal Form No. 5371** — **P.R.B. Form No. 54, Rule 252** — existing 10-column landscape Dead Body Challan.
3. **West Bengal Form No. 5370** — **P.R.B. Form No. 53, Rule 276** — existing UD Final Report layout.

## What changed

### Inquest / Surathal
- Removed the v208 replacement `INQUEST / SURATHAL REPORT` output.
- Lifecycle now delegates PDF/DOC generation to the established detailed INQUEST FORM renderer.
- Added separate `spotVisitDate` and `spotVisitTime`; these feed Final Report item 3 and are not confused with dead-body-found time.
- The officer-facing screen remains simple by default.
- A collapsed **সম্পূর্ণ সুরতহাল ফর্মের আরও তথ্য** section exposes every established Inquest field, including body description, identification marks, body-part injuries, discharges, ligature, foreign material, PO description, articles, probable cause, remarks and brief facts.

### Dead Body Challan
- Removed the v208 replacement table.
- PDF/DOC again use the existing W.B. Form 5371 / P.R.B. 54 landscape layout and existing 10 columns.
- `Means of Dispatch` is now populated from `flow.meansOfDispatch`, not `Direction from PS`.
- PM hospital/morgue, escort/messenger, documents sent, planned PM date and challan date/time are retained in the existing **Remarks** area rather than adding new printed columns.
- The identifying-police-officer column is populated with the current officer, while the underlying UD identification data is not overwritten.

### UD Final Report
- Removed the v208 replacement 11-item final-report layout and its lifecycle/debug note.
- Restored W.B. Form 5370 / P.R.B. Form 53 layout with only the established four numbered items before the narrative.
- Item 3 uses the separately entered **spot visit date/time**.
- Item 4 uses the separately entered **Final Report dispatch date/time**.
- PM number/date/report number/report received date/cause of death/medical findings appear inside the narrative because they are lifecycle facts, not new official form rows.
- The app still does not infer cause of death or foul play.
- `No foul play` wording appears only when the officer explicitly selected `notDetected`.
- If the officer selected `detected` or `inconclusive`, the final submission line does not falsely ask for routine filing; it submits for appropriate order/action while retaining the same form layout.

## Backward compatibility

Old `ud_lifecycle_v208` records remain readable. New fields:
- `spotVisitDate`
- `spotVisitTime`

load as empty strings for older records. They must be filled before a new Final Form can be finalized.

## Validation

Package validation performed in this environment:
- installer shell syntax
- static Dart delimiter/source scan
- hotfix-only mock install
- exact official-output contract markers
- ZIP integrity and SHA-256 manifest

Flutter SDK is not present in this environment, so `flutter analyze`, `flutter test`, PDF rendering and on-device visual comparison must still be run in Termux/GitHub CI.
