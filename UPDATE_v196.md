# INVESTIGO v196 — Multiple Case Entry Hotfix

## Fixed
- The bottom **CASES / মামলা** tab now opens a full Case Register instead of reopening only the latest case.
- Officers can create a second, third or later case directly from the Case Register.
- All saved cases can be searched, opened and edited independently.
- Case save now blocks accidental duplicate PS Case No. entries while preserving edits to the same case ID.
- Save button is guarded against repeated taps and reports persistence errors visibly.

## Data safety
- Existing `cases_v1` data is preserved.
- No migration or reset is required.
- Records continue to be upserted by immutable `CaseFile.id`.

## Verification
1. Create case `101/2026`.
2. Open **CASES / মামলা**.
3. Tap **New Case / নতুন মামলা**.
4. Create case `102/2026`.
5. Confirm both cases are visible and independently openable.
6. Edit either case and confirm the other remains unchanged.
