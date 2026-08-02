# UPDATE v195 — Windows Desktop Foundation

Version: `1.8.0-rc.12+195`

## Added

- Windows-first desktop workspace with permanent sidebar and wide-screen layout.
- Shared routing to existing Case, Case Diary, Final Documents, Reports, UD,
  NCR, Backup and Settings modules.
- Desktop status cards for cases, CDs, pending actions, UD and NCR.
- GitHub Actions Windows pipeline that creates `INVESTIGO.exe` and uploads a
  portable ZIP artifact.
- Platform detection helper and unit tests.
- Bengali/English language switching inside the desktop shell.

## Compatibility

Android startup remains unchanged. Desktop uses the same domain models, local
storage keys, official document renderers, officer profile and language
controller as the mobile application.

## Verification gate

The Windows artifact must be built by GitHub Actions and tested on a physical
Windows device before the desktop release is considered fully verified.
