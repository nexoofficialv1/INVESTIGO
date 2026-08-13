# INVESTIGO v207 — Simple Modern UI/UX Foundation

This is an ACTUAL Flutter UI/UX patch, not a mockup image.

## Design goal
INVESTIGO should remain legally/operationally capable while being usable by an officer who is not comfortable with complex software. Business logic stays in the existing engines. The user sees simple guided screens.

## Implemented in v207
- New reusable visual system: white/light background, indigo/royal-blue accent, rounded cards, large touch targets, low information density.
- Modern Dashboard replacement with 8 main actions and secondary tools separated from the primary workflow.
- New Case Register/Search screen with one search box, simple chips and large case cards.
- Modern Case Detail screen with one dominant `Create CD` action and simple case modules.
- CD Builder changed from many question groups on one long page to **one current question at a time** with progress, Back and Next.
- CD recommendations and pending form entries are collapsed behind optional panels; they never auto-select facts.
- Yes/No answers changed to two large buttons.
- Multi-choice investigation actions changed to large selectable rows.
- Structured BNSS forms changed to **one field/group at a time** with progress and Next/Back.
- Existing validation, Statement ↔ CD, multi-witness, Auto Sketch Map, Legal Search, bilingual form data and CD linkage remain backend capabilities.

## Not changed
- No investigative fact is invented.
- No legal workflow is removed.
- No generated final document format is intentionally changed by this UI patch.
- Splash/login redesign is not force-wired in v207 because the existing officer/profile boot flow must first be inspected at runtime to avoid breaking stored profiles.

## Runtime validation still required
The packaging environment has no Flutter SDK. Run after applying:

```bash
flutter analyze
flutter test test/simple_officer_ui_contract_test.dart
flutter test
flutter run
```
