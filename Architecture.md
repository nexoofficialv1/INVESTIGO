# INVESTIGO Architecture

## Product boundary
INVESTIGO is an offline-first investigation document application. The first market release focuses on document preparation, investigation guidance, locked official templates, local persistence, preview, PDF, DOC, print and sharing. Court tracking, malkhana, intelligence analysis and server sync are deferred.

## Domain separation

### 1. Regular Case Investigation Domain
Shared master data is used only by:
- Daily Case Diary (CD)
- Final CD
- Charge Sheet
- IF-5 / Final Form
- Sketch Map reference
- Index reference
- Accused, witness, arrest, seizure and investigation-action records

Sketch Map and Index are separate documents. When a CD action mentions preparation of either document, the application asks whether the officer wants to create, link or defer it.

### 2. UD Case Domain
A separate UD record supplies:
- Inquest
- Surathal narrative
- West Bengal Form No. 5371 Dead Body Challan
- PM requisition
- West Bengal Form No. 5370 UD Final Report

UD data must never be read from or written into a regular police case record.

### 3. NCR Domain
A separate NCR record supplies only the NCR workflow and the locked landscape prosecution report.

## Layers
- `models/`: immutable domain records and backward-compatible JSON conversion
- `data/domain/`: typed facades that prevent cross-domain storage access
- `services/`: narration rules, validation, PDF/DOC generation and local persistence
- `screens/`: officer input, review, approval, preview and export
- `test/`: domain, parser, document-data-flow and startup tests

## Official Template Engine
Every official document has a locked renderer. Layout geometry belongs to the renderer; case data is injected into named fields. A reference-backed renderer must not be replaced by a generic card or report layout.

Output rule:

`domain data -> locked template -> preview/PDF/DOC/print`

PDF is the print authority. DOC mirrors the same table structure and page orientation, but exact pagination must be verified in Microsoft Word/LibreOffice before release.

## Officer control
Narration parsing and suggested actions are advisory. No generated entry is final until the officer reviews and approves it.

## Sketch Map Professional Editor (v1.7.1)
The Regular Case domain keeps Sketch Map and Index as separate documents. The editor stores normalized x/y/width/height and rotation for every symbol. PDF export uses the same object geometry and rotation.

## v1.7.2 — Regular Case Final-Document Boundary

`RegularCaseDocumentData` is the only shared source for **Daily CD, Final CD,
Charge Sheet and IF-5**. It may aggregate regular-case CD rows and witness
statements, but it must never import or contain `UdCase` or `NcrReport`.

The final-document flow is:

```text
CaseFile + CdEntry[] + StatementEntry[]
        -> RegularCaseDocumentData
        -> FinalCaseDocumentService
        -> FinalCdDraft / ChargeSheetDraft / If5Draft
        -> separate officer review and approval
```

UD and NCR remain independent domains and independent storage keys.
`OfficialTemplateSpec` owns locked CD/NCR column ratios so renderers do not
silently redesign official forms.

## Final Case Document Review Layer
Regular Case data is transformed into three independent drafts: Final CD, Charge Sheet and IF-5. Each draft has its own persistence key, validation, approval state and renderer. A change or approval in one document does not automatically approve another document.

## Final document template lock (v1.7.4)
Final CD uses the Case Diary four-column grid. Charge Sheet and IF-5 are separate renderers over the Regular Case domain. IF-5 follows W.B.P. Form No. 39 item numbering and never reads UD or NCR data.


## RC-1 feature-freeze boundary (v1.7.6)
`RcFeatureManifest` is the machine-readable release boundary. New modules cannot enter RC-1 unless this manifest, `Phases.md` and release tests are updated together. The Release Center screen exposes the same scope to officers and testers.

## RC-1 Profile Binding and Documents
All generated documents bind Police Station, District, Court, Hospital, Morgue and FSL destinations from OfficerProfile. A Form and FSL 5203 are regular-case documents; UD challan remains in the UD domain.

## RC-1 v185 document export parity
FSL Form 5203 and A Form now use dedicated PDF and DOC renderers. Dashboard routes IF5/CS directly to the Regular Case final-document workspace.

## RC-1 completion update (2026-08-02)

- `SettingsScreen` is the single settings hub for Officer Profile, Backup & Restore, License, Backend, Language and RC-1 status.
- Dashboard uses an officer-centric header and exposes Settings from both the header and bottom navigation.
- Case Diary PDF rows are content-height driven; fixed estimated row heights are prohibited.
- UD and NCR document identity fields are bound to the current Officer Profile at save/export time.
- FSL Form 5203 and A Form remain inside the Regular Case Forms workspace.

## RC-1 v189 — Official CD rendering boundary
The Form 5363 renderer now uses `OfficialTemplateSpec.cdColumnRatios` as the single layout source for PDF and DOC output. Investigation actions are rendered as continuous rows without horizontal action dividers, matching the official case-diary visual structure. Header normalization derives the case year, official date display, Roman CD number, and station short name from case/profile data.

## v193 — Bilingual Render and Narration Pipelines

- `BilingualTranslationService` prepares Bengali/English ML Kit models and translates Statement/CD content at render time without replacing the original stored text.
- `InvestigationNarrationService` creates approved pending CD actions; `CdBuilderScreen` consumes those actions into the official Form 5363 table.
- `UdNarrationService` converts a single Bengali/English narrative into the shared `UdCase` field map. Inquest, Form 5371 and UD Final Report continue to render from that one model.

## v194 Document Preview Pipeline

CD and Statement preview are independent of translation-model readiness. One cached PDF future feeds preview, print and PDF sharing; DOC export is separately guarded.

<!-- v195-desktop-foundation -->
## v195 Windows desktop foundation

The application now has a platform entry boundary. Android continues to open
`DashboardScreen`; Windows, macOS and Linux desktop targets open
`DesktopWorkspaceScreen`. Both routes reuse the same domain models,
`LocalStoreService`, official document renderers, profile and language
controller. The initial certified target is Windows.

## v204 — Offline Legal Reference Layer
INVESTIGO includes a local BNS/BNSS searchable index. Search/index correspondence data is kept separate from verified statutory text. Verified records carry explicit source provenance; comparison notes are never presented as authoritative bare-Act text. Case Detail and CD Builder link into the same LegalReferenceService.

## v205 — Bilingual BNSS Forms Layer
Bilingual statutory/investigation form templates are stored separately from the legacy form generator. English and Bengali are explicit editable variants; template provenance and section linkage are metadata. Final-saved forms can create PendingCdAction entries so the CD engine consumes the action without retyping.

## v206 — Structured Form Workflow
The bilingual form layer is now data-driven. FormNotice stores backward-compatible `workflowData`; schema-defined fields render the final form body and create date/time/place-aware PendingCdAction records. Raw body remains editable, but operational facts are collected through selectors and repeaters.

## v207 — Simple Officer UI/UX
The primary mobile presentation layer uses a reusable INVESTIGO design system and guided single-step workflows. Complex legal/investigation engines remain separate from the visual layer. CD and structured forms expose one current question at a time while retaining the underlying complete state and validation.

## v208 — Critical Data Integrity & UD Lifecycle
UD documents are stage-gated: registration → Section 194 inquest/surathal → dead-body challan/PM forwarding → PM completed → PM report received → final form. The final report is generated only from officer-entered/confirmed findings after PM report receipt. Dashboard UD routing uses the lifecycle screen. Case entry stores FIR/case facts only; investigation actions belong to the CD workflow. General Reports open without silently binding the latest case; case-linked reports are opened from the case workspace.

## v208.1 — Official UD Format Preservation
The v208 lifecycle remains the source of stage/state and chronology, but UD printing is adapter-based. Inquest delegates to the established detailed INQUEST FORM renderer. Dead Body Challan delegates to the established W.B. Form No. 5371 / P.R.B. Form No. 54, Rule 252 renderer. UD Final Report keeps the established W.B. Form No. 5370 / P.R.B. Form No. 53, Rule 276 layout while substituting only officer-confirmed PM/final facts and corrected spot-visit/final-dispatch times. Lifecycle/debug notes and replacement columns are prohibited in official outputs.

## v209.1 — Offline Product Gate
- Startup sequence is Splash -> Offline License Gate -> Officer Profile -> Workspace.
- Case creation exposes Manual Entry and Case Parser as first-class paths.
- Licensing uses Ed25519 signatures; only the public verification key ships in the app.
- Runtime operation remains offline; no license server is required.
