# INVESTIGO RC-1 Build Status

Version: `1.8.0-rc.1+180`

## Completed source validation

- Required documentation present
- Regular Case, UD and NCR domain boundaries present
- Official-template marker validation passed
- Release source validation script passed
- ZIP integrity will be checked before delivery

## To be completed by GitHub Actions

- `flutter pub get`
- Dart formatting
- Flutter analysis
- Automated tests
- Debug APK build
- Release APK build

## Required before stable release

- Install Debug APK on a real Android device
- Verify CD save/reopen and long-CD preview
- Compare CD, NCR and UD PDF/DOC prints with the supplied reference forms
- Record and fix all blocking defects

This package is an RC source candidate, not a production-certified stable release.

## RC-1 complete source checkpoint — 1.8.0-rc.5+186

Completed in source:
- CD content-height rows and compact official grid.
- Settings hub and officer profile routing.
- Dashboard Settings navigation and INVESTIGO branding.
- Profile-bound PS/District for UD and NCR.
- Dead Body Challan common preview/PDF/DOC path.
- FSL Form 5203 and A Form source/export support.

Local checks completed in the packaging environment:
- Release validator: PASS
- Preflight validator: PASS
- Dart delimiter/string structural scan: PASS
- Local relative-import check: PASS
- ZIP integrity: pending packaging step

Flutter analyze/test/APK compile must run in GitHub Actions because Flutter SDK is not installed in the packaging environment.
