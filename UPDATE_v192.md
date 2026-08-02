# INVESTIGO RC-1 v192 — Form 39 release-validator fix

## Fixed
- Release validation now accepts the official specimen caption `W.B.P Form No. 39`.
- The validator also accepts harmless case and punctuation variants such as `W.B.P. FORM NO.`.
- The PDF-visible Form 39 caption was not changed, so it remains aligned with the supplied official specimen.

## Validation
Run:

```bash
python3 tools/validate_release.py
```

Expected result: `RELEASE VALIDATION PASSED`.
