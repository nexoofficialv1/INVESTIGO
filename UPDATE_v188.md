# INVESTIGO RC-1 Hotfix v188

- Fixed multiline structured-field parsing in `DocExportService._field`.
- Removed `multiLine: true`, because `$` was matching the end of every line and truncating `DOCUMENT INDEX` after the first row.
- A Form DOC now preserves all docket index rows, including `2 | Sketch Map | 4`.
- The same fix also protects multiline FSL exhibit and custody sections.
