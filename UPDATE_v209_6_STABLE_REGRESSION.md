# INVESTIGO v209.6 Stable Release Regression Hardening

- Extracted backup/restore persistence and binding logic into BackupRestoreService.
- Current-format restore rejects backups from another application.
- Restore validates all values before mutating preferences.
- Exact-state restore removes stale non-license app preferences.
- Offline license/trial preferences are never backed up or overwritten by restore.
- Added trial-device and licensed-license-ID restore binding tests.
- Added Bengali/English preference reload persistence test.
- Existing multiple-case, CD multipage, DOC export and v209 product-gate tests are now required by release validation.
