# Final source status — v0.9.5+95

Included:
- Bengali / English language selector
- Existing case, CD, forms, report, UD and investigation source
- Official-style CD PDF/DOC template
- New NCR tab, NCR draft storage, PDF preview/share and DOC export
- NCR A4 landscape multi-column layout based on the supplied reference image
- GitHub Actions debug and unsigned release APK workflow
- Termux GitHub push script and instructions

Not executed in this container:
- `flutter analyze`
- Android APK compilation
- real-device PDF/DOC print comparison

The GitHub Actions workflow performs analyze and APK compilation after push. Any analyzer/build error must be resolved from that run log before calling the APK production-ready.
