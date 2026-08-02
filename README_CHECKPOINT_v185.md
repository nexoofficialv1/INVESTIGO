# INVESTIGO RC-1 Internal Checkpoint v1.8.0-rc.4+185

This checkpoint is not yet a stable release.

Implemented:
- Dead Body Challan PDF fixed-height grid reduced to improve preview stability.
- FSL Form 5203 dedicated DOC packet with exhibit list, custody table, challan and labels.
- A Form dedicated DOC renderer.
- Dashboard IF5/CS and PDF Export cards open the final case document workspace.
- Duplicate FSL getter removed.
- Contract tests added for FSL and A Form DOC output.

Still required before final push:
- Flutter format/analyze/test/build in CI.
- Real-device Dead Body Challan preview/share test.
- Physical print comparison for Form 5371, Form 5203 and A Form.
