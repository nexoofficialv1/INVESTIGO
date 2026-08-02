# UPDATE v194 — CD Preview, PDF and DOC Reliability

## Completed

- CD preview no longer aborts when the optional translation model is unavailable.
- Generated PDF bytes are cached and reused for preview, printing and sharing.
- Preview now displays loading, error details and Retry instead of a blank page.
- PDF and DOC export/share errors are caught and displayed.
- Statement preview uses the same non-blocking document pipeline.
- Translation model acquisition has a 20-second timeout and one-minute failure cooldown.
- PDF font loading has an offline English fallback.
- Added regression contract coverage.
