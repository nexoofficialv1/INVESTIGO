# INVESTIGO Architecture

## 1. Product boundary
INVESTIGO is an offline-first Flutter mobile application for police investigation workflows. The first market release focuses on case work, CD, NCR, UD documents, sketch map/index, official forms, PDF/DOC export, and officer-reviewed smart drafting. Court tracking, duty/leave, intelligence analysis, and server sync remain deferred until field feedback.

## 2. Runtime layers

### Presentation
`lib/screens/` and `lib/widgets/` contain forms, dashboards, preview screens, and editors. UI language is controlled by `AppLanguageController`.

### Domain models
`lib/models/` contains case, CD, pending CD action, investigation action, statement, sketch map, NCR, UD, officer profile, forms, and backend configuration models.

### Application services
`lib/services/` contains local persistence, CD generation, narration parsing, PDF/DOC generation, compliance, form generation, parsing, and optional backend access.

### Persistence
The current release stores JSON in `SharedPreferences` through `LocalStoreService`. This is suitable for early offline testing but not the final multi-user database. Migration to a transactional local database must occur before production-scale use.

### Document rendering
Official documents must be template-locked. Preview, PDF, DOC, and print must use the same field mapping and page rules. A supplied official reference must never be replaced with a generic layout.

## 3. Core workflows

### Case workflow
Case Master → Investigation Actions → Daily CD → Sketch Map/Index (separate documents) → Statements/Forms → Final CD → Charge Sheet/IF5.

### UD workflow
UD Master → Officer narration → Inquest/Surathal draft → Dead Body Challan → UD Final Report. Shared facts are entered once and reused, but each document remains separately editable and approvable.

### Smart drafting workflow
Officer text/voice → offline parser → detected actions/facts → editable suggestions → duplicate/rule validation → officer approval → saved investigation action and/or pending CD row. No automatic finalisation is allowed.

## 4. Investigation rules
- PO Visit: normally once; a repeat requires a recorded justification.
- Witness examination: repeatable and may occur in CD-1 or later CDs.
- Sketch Map and Index: separate documents; CD may link to them.
- FIR receipt, first PO visit, first sketch map, and first index: normally-once actions.
- Arrest, seizure, raid/search, requisition follow-up, and witness examination: repeatable with entity/context differentiation.

## 5. Deferred architecture
The following are intentionally deferred: court case management, malkhana/property lifecycle, officer duty/leave, intelligence/link analysis, and online sync. Their future integration points must not be hard-coded into current forms.

## 6. Change rule
Any module boundary, data flow, persistence, document renderer, or external integration change must update this file in the same commit.
