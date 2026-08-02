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
