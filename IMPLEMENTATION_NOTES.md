# v3.4 FSL Simple Step-by-Step Entry Module

This patch improves FSL Form Fill Up usability without changing the official Form 5203 output format.

## Key Changes

- FSL form now has a simple step-by-step entry module.
- Pre-filled fields remain available from selected case and officer profile.
- Each official FSL point has a separate input area before preview/export.
- Exhibit entry is now row-based with one card per exhibit:
  - Label / Exhibit Mark
  - Description of exhibit
  - How and when found and by whom
  - Ownership of exhibit
  - Remarks (editable)
- Multiple exhibits can be added with “Add Exhibit”.
- Persons in custody now have one card per person:
  - Full name
  - Occupation
  - Age
  - Sex
  - Date & time of arrest
  - Bail/Custody status
  - Court
- Multiple persons in custody can be added with “Add Person”.
- The structured entry is converted into the existing official FSL package body before Preview/PDF/DOC export.

## Official Format Rule

The PDF/DOC output must keep the official West Bengal Form No. 5203 format. UI entry is simplified, but the final form layout should not be redesigned.
