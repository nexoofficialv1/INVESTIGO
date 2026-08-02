# UPDATE v190 — Final CD Template Test Alignment

## Completed
- Updated the stale `final_template_lock_test.dart` expectation from the retired 10/10/13/67 ratios.
- Locked the final CD test to the official 9/9/11/71 ratios introduced in v189.
- Added a consistency assertion so `finalCdColumnRatios` must remain identical to `cdColumnRatios`.

## Runtime impact
- No application runtime or renderer code changed.
- This update only aligns the regression test with the already-updated official Form 5363 renderer.
