# INVESTIGO Security

## Security objective
Protect sensitive investigation and personal data while keeping the first release usable offline.

## Current posture
- Primary case work is local/offline.
- Smart drafting is rule-based and local.
- No online AI is required.
- Optional backend code is experimental and must remain disabled unless explicitly configured and reviewed.

## Mandatory controls before production release
- App-level authentication or device-bound access control.
- Encrypted local database and encrypted backups.
- Automatic screen lock after inactivity.
- Role/permission model if multiple users are introduced.
- Audit events for create, edit, approve, export, delete, restore and migration.
- Release signing keys stored outside the repository and CI logs.
- Secure file sharing using temporary files and clear user confirmation.
- No secrets, tokens, passwords, private keys or live case data in Git.

## Data minimisation
- Collect only fields required for investigation/document generation.
- Avoid duplicating full personal data across records when a case/entity ID is sufficient.
- Do not include sensitive data in analytics or crash telemetry.

## Network policy
The first market release should work without network access. If a network feature is enabled later:
- TLS is mandatory.
- Certificate/domain validation is mandatory.
- API keys must be server-side or user-supplied securely.
- Requests must be authenticated and authorised.
- Sensitive fields require masking or approved end-to-end protection.
- Offline data must not auto-upload without clear configuration.

## Documents and exports
- Exported PDF/DOC files contain sensitive data and must show a warning before sharing.
- Temporary export files should be deleted when no longer needed.
- Preview must not silently upload files.

## Threats tracked
- Lost/unlocked phone.
- Unauthorised export/share.
- Corrupt or tampered backup.
- Embedded API secret.
- Accidental online transmission.
- Stale data after restore/migration.
- Unapproved generated narrative being treated as fact.

## Change rule
Any permission, dependency, network call, storage method, export mechanism, authentication, logging, or encryption change must update this file.
