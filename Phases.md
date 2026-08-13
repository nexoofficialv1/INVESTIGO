# INVESTIGO Phases

## Current consolidated build: 1.7.0

### Foundation — completed
- Stable GitHub Actions build
- Offline local storage
- Bilingual application framework
- Domain models and basic screens
- Mandatory documentation policy

### Domain separation — completed in source
- Regular Case Investigation
- UD Case
- NCR

### Official UD Template Engine — in progress
- Inquest: retained from existing accepted workflow
- Dead Body Challan: Form 5371 locked landscape renderer added
- UD Final Report: Form 5370 locked portrait renderer added
- PDF and DOC commands exposed in UD screen
- Physical print calibration still required

### Next consolidated work
1. CD locked renderer and multi-page row flow
2. NCR landscape calibration
3. Sketch Map/Index linkage and symbol library
4. Final CD, Charge Sheet and IF-5 locked workflow
5. Offline narration and duplicate-action rule hardening
6. Bengali/English template review
7. Full regression tests
8. Release Candidate APK

## Deferred after market feedback
- Court diary and hearing tracking
- Malkhana/property lifecycle
- Officer duty/leave tools
- Intelligence/link analysis
- PostgreSQL sync and multi-device deployment

- [x] Professional Sketch Map landmark library and all-object rotation (v1.7.1 checkpoint)
- [ ] Locked CD renderer calibration
- [ ] NCR exact print calibration

## Internal checkpoint v1.7.2

- [x] Created typed Regular Case final-document source.
- [x] Final CD, Charge Sheet and IF-5 drafts derive from that one source.
- [x] Added case-closure validation before approval.
- [x] Locked CD and NCR template measurements in one specification.
- [x] Added boundary and template-ratio tests.
- [ ] Connect the three drafts to separate review screens.
- [ ] Bind official Final CD/CS/IF-5 PDF and DOC templates.

## Internal checkpoint v1.7.3
- Final CD review/save/approval/preview: implemented.
- Charge Sheet review/save/approval/preview: implemented.
- IF-5 review/save/approval/preview: implemented.
- Exact physical calibration remains part of release-candidate print testing.

- [x] v1.7.4 Final CD four-column renderer and expanded W.B.P. Form 39 field order.
- [ ] Physical print calibration against blank departmental forms before RC-1.


## Internal checkpoint v1.7.6 — RC-1 feature freeze
- [x] RC-1 scope is encoded in `RcFeatureManifest`.
- [x] Court tracking, malkhana, intelligence and online sync are explicitly deferred.
- [x] Added in-app Release Center so scope is visible without reading source files.
- [ ] Complete export consistency and physical print calibration before RC-1.


## RC-1 consolidated candidate — 1.8.0-rc.1+180

Status: source packaged for one GitHub push and CI APK build.

Before stable release, complete the device and physical-print checklist in `RC_CHECKLIST.md`.

## RC-1.3 (in progress)
- Global Officer/Station profile binding
- Officer-centred dashboard
- Dead Body Challan action error handling
- FSL Form 5203 accessibility and dynamic profile defaults
- A Form docket index

- [x] RC-1 v185: Dead Body Challan layout safety, FSL/A Form DOC parity, dashboard final-document navigation.

## RC-1 completion batch — 2026-08-02

Completed in source:
- Compact/auto-height CD PDF rows.
- Unified Settings hub.
- Current-profile Police Station and District binding for UD and NCR.
- Officer-centric dashboard branding/navigation.
- Dead Body Challan preview routed through the common PDF/DOC preview screen.
- FSL Form 5203 and A Form catalog/export retained and validated.

Pending outside this source package:
- GitHub Actions Flutter compile/test/APK build.
- Real-device and physical-print calibration before Stable release.

## RC-1 v189
- [x] Form 5363 PDF continuous official table
- [x] Form 5363 DOC continuous official table
- [x] Official 9/9/11/71 column lock
- [x] Roman CD number and case-derived year/date
- [ ] Bilingual narrative conversion engine
- [ ] Charge Sheet official specimen lock
- [ ] IF-5 official specimen lock

## RC-1 v191 — Official output repair
- CD saved entry rows: repaired.
- Dead Body Challan Form 5371 PDF flex overflow: repaired.
- Dedicated FSL Exhibit Challan preview: added.
- Charge Sheet / IF-5 official W.B.P. Form 39 PDF and DOC renderers: added.
- Full Flutter CI/APK validation: pending GitHub Actions.

## RC-1 v193 completed

- FSL custody dropdown legacy-data repair
- Statement and CD Bengali/English render translation
- Smart daily narration entry point and direct CD Writer hand-off
- UD single-narration auto-fill for all linked UD documents

## RC-1 v194

Completed mobile CD preview/PDF/DOC reliability and non-blocking translation fallback.

<!-- v195-desktop-foundation -->
## Desktop phase D1 — foundation

- Add a Windows-first wide-screen shell and sidebar navigation.
- Reuse current Case, CD, Report, UD, NCR, Backup and Settings screens.
- Add GitHub Actions Windows release packaging.
- Gate completion on a successful CI build and physical Windows verification.

Later phases may add multi-window editing, searchable register tables,
installer signing and PostgreSQL synchronization.

## v204 — BNS/BNSS Legal Search — Completed
- Offline BNS + BNSS section/subsection index
- IPC/CrPC correspondence search
- Verified official core text
- Bengali helper explanation / on-device translation
- Case Detail + CD Builder law shortcuts

## v205 — English + বাংলা BNSS Forms Library — Completed
- Section 35(3) appearance notice
- arrest memorandum reference form
- Section 94 production notice/order
- Section 179 witness attendance notice
- Section 49 personal search memorandum
- medical examination requisition
- FSL forwarding reference
- Section 193(3)(ii) progress intimation
- Law Search shortcut and CD auto-link

## v206 — Structured Bilingual Forms — Completed
- Date/time selectors
- recipient/witness/person particulars
- arrest-ground checklist
- repeating document/article/exhibit/progress rows
- service/acknowledgement tracking
- final validation
- date/time/place-aware CD linkage

## v207 — Simple Modern UI/UX Foundation — Completed
- Modern dashboard
- Simple case register/search
- Modern case workspace
- One-question CD wizard
- One-step-at-a-time structured forms
- Large touch targets and collapsed advanced panels

## v208 — Critical Integrity Fix — Completed in source patch
- Stage-gated UD workflow
- PM-day/previous-day challan chronology validation
- PM report receipt gate before UD Final Form
- No automatic foul-play/cause-of-death conclusion
- Correct dispatch/PM fields in lifecycle documents
- Case duplicate check + required facts + date/time pickers
- Case Entry no longer asks investigation-action questions
- Report templates no longer assert unverified investigation actions
- Stable report draft IDs + reopen saved v208 reports

## v208.1 — Official UD Format Preservation Hotfix
- Restored detailed Inquest output without changing lifecycle gating
- Restored 10-column W.B. Form 5371 Dead Body Challan
- Restored W.B. Form 5370 / P.R.B. Form 53 Final Report layout
- Added separate spot-visit date/time for Final Report item 3
- Preserved full Inquest field fillability under a collapsed simple-officer section
- Corrected Means of Dispatch mapping without altering the printed 5371 column

## v209.1
- Branded Flutter/native Android splash.
- Prominent offline Case Parser entry.
- 14-day local trial and renewable yearly signed offline license.
