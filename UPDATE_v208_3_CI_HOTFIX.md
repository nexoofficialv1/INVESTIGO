# INVESTIGO v208.3 CI Hotfix

## Fixed
- Legacy CrPC/IPC cross-reference searches now match old section numbers by exact extracted section token.
- Example: `CrPC 161` resolves to the BNSS row whose `oldSection` contains section `161`, rather than accidentally matching unrelated short old-section values such as `1`.

## Unchanged
- No official PDF/DOC format was changed.
- No Case/CD/Statement/UD lifecycle workflow was changed.
- No Surathal/Inquest, W.B. Form 5371 Dead Body Challan, or W.B. Form 5370 Final Report layout was changed.

## Version
`1.8.0-rc.16+2083`
