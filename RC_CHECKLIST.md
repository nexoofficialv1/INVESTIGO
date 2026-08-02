# INVESTIGO Release Candidate Checklist

## Build gates
- `python3 tools/validate_release.py`
- `dart format lib test`
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test --reporter=expanded`
- `flutter build apk --debug`
- `flutter build apk --release`

## Device checks
- Fresh install and upgrade install
- Bengali/English switch retained after restart
- Draft save, close app, reopen, edit and export
- 25+ CD entries and 20+ page PDF
- CD Preview/PDF/DOC contain the same rows
- NCR renders in A4 landscape
- Surathal, Form 5371 and Form 5370 print comparison
- Sketch Map rotation/resize survives save and PDF export
- Final CD, Charge Sheet and IF-5 remain separately approved

## Data isolation
- Regular Case data never appears in UD/NCR
- UD data never appears in Regular Case/NCR
- NCR data never appears in Regular Case/UD

## Release decision
A release candidate is not production-ready until the physical printed forms are compared with the supplied references and all blocking issues are closed.
