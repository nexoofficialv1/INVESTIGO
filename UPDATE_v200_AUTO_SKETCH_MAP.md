# INVESTIGO v200 — Auto Sketch Map + Index

## Completed
- CD-I and later PO workflow now asks Exact PO separately.
- When Sketch Map/Index = Yes, Exact PO + North/South/East/West are mandatory.
- Once those five facts are complete, CD Builder can auto-create the case sketch draft.
- Auto draft uses X = PO, A = North, B = South, C = East, D = West, plus North arrow.
- Boundary text is heuristically rendered as Road/Pond/House/Field/etc where possible; uncertain items remain editable draft objects.
- Officer validation gate: CD cannot be generated with Sketch=Yes until the saved sketch fingerprint is approved.
- Auto validation screen supports drag correction, regeneration, and opens the existing full Sketch Map Builder for label/size/rotation/add-remove/PDF/DOC work.
- Any edit changes the map fingerprint and automatically makes the old approval invalid.
- Continuation CD PO workflow is now granular instead of one free-text PO-details box.

## Existing module reused
The repository already contains Sketch Map Builder v2.4 with drag, rotation, index, PDF/DOC preview. v200 links the CD workflow to that module instead of duplicating it.

## Apply
Run `bash apply_v200_auto_sketch.sh` from the extracted patch directory while the INVESTIGO repo is at `~/INVESTIGO_REPO`, or pass repo path as first argument.

## Verify
`flutter analyze`
`flutter test`

## Important
The generated map is a DRAFT. It must be reviewed by the investigating officer. The app does not infer unprovided physical facts; labels are taken from officer-entered Exact PO and N/S/E/W data.
