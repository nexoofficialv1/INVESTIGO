# INVESTIGO Phases

## Release goal
The first market release is an offline, officer-reviewed investigation and official-document application. It is not yet a department-wide server system.

## Phase 1 — Foundation — In progress
- Flutter CI: analyze, test, debug APK, release APK.
- Bengali/English application language.
- Offline local persistence.
- Error-visible PDF preview.
- Required project documentation.

Exit criteria: CI green, APK installs, no startup crash, backup/restore smoke test passes.

## Phase 2 — Core investigation — In progress
- Case Master and case detail.
- Daily CD entry rows and long-document pagination.
- CD-1 versus subsequent-CD rules.
- Investigation action register and duplicate warnings.
- Officer-reviewed offline narration drafting.
- Sketch Map and Index kept as separate linked documents.

Exit criteria: CD editor data appears identically in preview/PDF/DOC; 20+ page test passes; repeat rules behave correctly.

## Phase 3 — Official UD/NCR documents — In progress
- NCR in locked landscape format.
- Inquest/Surathal using supplied reference.
- West Bengal Form No. 5371 Dead Body Challan in locked landscape format.
- West Bengal Form No. 5370 UD Final Report in locked portrait format.

Exit criteria: reference comparison approved on real device and printed PDF; no generic substitute template remains.

## Phase 4 — Case completion documents — Planned for first release
- Final CD as a separate document.
- Charge Sheet as a separate document.
- IF5/Final Form as a separate document.
- Seizure, arrest, inspection, personal-search, notice and requisition forms where official references are available.
- Complete case document index/bundle without merging independent documents into one form.

## Phase 5 — Release candidate
- Real-case testing with anonymised data.
- Bengali font and pagination verification.
- Save/reopen/export consistency.
- Crash and recovery testing.
- Security and privacy review.
- Signed release build and release notes.

## Deferred updates
Court management, malkhana/property lifecycle, officer duty/leave, intelligence/link analysis, and online/server sync will be considered only after field use and feedback.

## Status rule
A phase can be marked complete only when its exit criteria have evidence from CI and real-device testing.
