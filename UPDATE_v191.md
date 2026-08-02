# INVESTIGO RC-1 v191 — Official Output Repair

## Completed
- Daily CD preview now renders saved entry rows directly; removed the fixed-page `Expanded` wrapper that could leave the body blank.
- CD page chunk limit reduced to prevent oversized rows.
- Dead Body Challan Form 5371 rebuilt as a stable landscape table without rotated nested Flex widgets.
- Added a dedicated **FSL Exhibit Challan Preview** action with exhibit labels.
- Charge Sheet and IF-5 PDF/DOC now use the official W.B.P. Form No. 39 / Final Form layout:
  - fields 1–17,
  - property table,
  - accused sections,
  - witness table,
  - brief facts,
  - dispatch and signature blocks.
- Added static regression tests for all four repairs.

## Validation note
The package includes source-level lexical and contract checks. GitHub Actions must run `dart format`, `flutter analyze`, `flutter test`, and the Android APK build.
