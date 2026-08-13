# INVESTIGO v208.2 — CI Hotfix

## Purpose
This is an incremental hotfix for the v208.1 source already on `main`.
No official police/court output template is changed by this patch.

## Fixed
1. **Legacy legal cross-reference priority**
   - An explicit legacy-code query such as `CrPC 161` now prioritizes the BNSS row whose `oldSection` is `161`.
   - Therefore `CrPC 161` resolves to **BNSS 180 — Examination of witnesses by police**, instead of the unrelated present BNSS section 161.
   - The same priority rule applies to explicit IPC queries against BNS mappings.

2. **Stale RC-1 UI contract**
   - The legacy test expected one literal label `Smart Narration → CD` and the removed one-tap UD auto-fill flow.
   - The test now verifies the current simple-card Smart Narration action and the staged UD lifecycle (`Inquest -> PM -> PM Report -> UD Final Form`).

## Format lock
- CD format: unchanged.
- Statement format: unchanged.
- Forms/Notices formats: unchanged.
- UD Inquest/Surathal format: unchanged.
- Dead Body Challan W.B. Form 5371: unchanged.
- UD Final Report W.B. Form 5370: unchanged.

## Expected CI impact
The two failures seen in Android/Windows run for commit `e6e5b9990dc70c1a424e0978b0b5d453a82e7f56` are targeted by this hotfix.
Full Flutter CI must still be treated as the final verification.
