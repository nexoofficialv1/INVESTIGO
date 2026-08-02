# INVESTIGO RC-1 Hotfix v187

- Fixed A Form DOC contract failure where case and charge-sheet numbers containing `/` were emitted as the HTML entity `&#47;`.
- Centralized DOC text escaping so all export templates preserve human-readable slash-delimited official numbers such as `10/2026` and `1/2026`.
- Existing `doc_export_contract_test.dart` now validates this regression path.
