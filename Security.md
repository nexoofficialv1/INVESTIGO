# INVESTIGO Security

## First-release principles
- Offline-first operation
- No automatic upload of case, UD or NCR data
- No public AI transmission
- Minimum Android permissions
- Officer approval before final document generation

## Sensitive information
Names, addresses, phone numbers, medical facts, witness statements and investigation narratives are sensitive. Logs must not print full record payloads.

## Storage
Current local storage is suitable for testing and controlled deployment, not yet certified for unrestricted production use. Before public deployment add:
- encrypted local database or encrypted record payloads
- app lock/PIN or device-biometric gate
- secure backup with user-controlled export
- audit log for create/edit/final/export events
- retention and deletion controls

## Export
PDF/DOC files may contain sensitive data. The application must warn before sharing and use temporary files that can be removed after export.

## Backend
Deferred. Future server communication must use TLS, short-lived tokens, role-based access and server-side audit records. API secrets must remain on the server.

## Sketch map privacy
Sketch maps and landmark labels are stored locally under the Regular Case domain. They are not uploaded by the offline assistant.

## Final-document separation

Final CD, Charge Sheet and IF-5 share regular-case facts but retain separate
approval states. UD and NCR data are excluded by type and storage boundary.
This reduces accidental cross-case disclosure and prevents an NCR/UD record
from being inserted into a regular-case prosecution document.

## Final document approval
Approval is explicit and local to one document. Validation runs before approval. Export does not silently approve a draft. UD/NCR records are not queried while building Regular Case final documents.

## Final-document approval
Final CD, Charge Sheet and IF-5 approvals remain independent. Export does not imply approval, and draft metadata remains local.


## v1.7.6
The Release Center reads static feature metadata only and does not read, transmit or modify case data.

## Station identity validation
Document export requires a complete local OfficerProfile. No location is hard-coded and no profile data is transmitted by the offline document generators.

## v185
FSL and A Form generation remains offline. Profile data is read locally and embedded only in user-requested exports.

## Configuration integrity

Police Station and District are no longer supplied by hard-coded application defaults. They are taken from the locally stored Officer Profile. Settings changes remain on-device unless the officer explicitly enables/configures a backend.

## RC-1 v189
The official CD renderer continues to use Officer Profile and Case data only. No station, district, officer identity, or case year is hard-coded in production output.

## v193 on-device translation

Bengali/English translation uses downloadable ML Kit language models. The app downloads the language models once and performs translation on the mobile device. Original police narrative remains stored locally and officer verification is required before final document export. Translation attribution is displayed in the relevant screens.

## v194 Export Handling

PDF bytes remain in preview memory; DOC files use the app temporary directory and platform share sheet. No silent upload is introduced.

<!-- v195-desktop-foundation -->
## v195 Windows security notes

The portable build stores application data in the platform application-data
location selected by Flutter plugins. No administrator privilege is required.
Only trusted GitHub Actions artifacts should be executed. Code signing,
installer signing and managed-device deployment remain future release gates.

## v204 — Legal-source integrity
The UI distinguishes official verified statutory material from comparison/index notes. Helper Bengali machine translation is labelled non-official. Draft-bill text must not override enacted section numbering.

## v205 — Form provenance
A reference/sample form is not silently promoted to statutory text. The UI exposes source/provenance notes; Bengali helper forms are not labelled as official statutory translations unless separately authenticated. Officer-entered facts remain reviewable before Final Save.

## v206 — Officer validation
Final Save is blocked when mandatory structured facts are incomplete. The software must never auto-select arrest grounds, invent service/acknowledgement, fill seized articles, infer medical/FSL findings, or guess the unlabeled row 5 of the supplied arrest-memo reference.

## v207 — UX safety
Simplification must not silently auto-select investigation facts, legal conclusions, service status, arrest grounds or evidence. Suggestions stay optional and visibly separate from officer-entered facts.

## v208 — Record integrity
INVESTIGO must never infer cause of death, foul play, completion of inquest, PM completion, PM report receipt, or final investigation result. Each is an explicit officer-confirmed stage. Pending viscera/FSL/chemical/other reports block UD finalization.

## v208.1 — Official-document integrity
Official form structure is immutable at the lifecycle layer. Workflow metadata must not appear as extra printed headings, columns or debug notes. Final-report narrative may be assembled only from explicit PM-report fields and officer-entered final summary/foul-play assessment.

## v209.1 offline licensing
- Ed25519 public-key verification is used for activation.
- The private signing key is NOT part of the app/repository.
- License is bound to the locally generated installation code.
- Clock rollback greater than tolerance blocks access until system date/time is corrected.
- Offline trial markers reset after uninstall/data wipe by design.
- Trial expiry locks the entire app to activation-only mode; backup/export/restore are unavailable.
- Android automatic app-data backup/restore is disabled so reinstall starts with empty app-private data.
- Trial backups are installation-bound and cannot be restored into a fresh reinstall trial.
- License/trial preference keys are excluded from backup payloads.
