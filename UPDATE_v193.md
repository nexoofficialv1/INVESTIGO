# UPDATE v193 — Smart Narration, Translation and FSL Repair

## Completed

1. Fixed the FSL custody `Sex` dropdown crash caused by legacy placeholder text.
2. Added Bengali ↔ English on-device translation for Statement and CD PDF/DOC output.
3. Added explicit Statement translation controls and one-time model preparation.
4. Connected the existing Investigation Assistant to Case Detail and Investigation screens.
5. Added direct `Smart Narration → CD` workflow and `এখন CD বানান` navigation.
6. Added a single UD/Inquest narration box that populates the shared UD record used by:
   - Inquest / Surathal Report
   - Dead Body Challan — Form 5371
   - UD Final Report
7. Added regression tests for FSL placeholders, narration entry points and UD parsing.

## Translation behaviour

- Bengali and English models are downloaded once on the device.
- After model download, translation processing is performed on-device.
- Original stored investigation/statement text is retained; preview/export renders it in the selected app language.
- Officer verification remains mandatory before final save/export.
