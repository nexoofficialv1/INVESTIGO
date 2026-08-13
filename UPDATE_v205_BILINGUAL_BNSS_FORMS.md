# INVESTIGO v205 — English + বাংলা BNSS Forms Library + CD Auto-Link

## Scope
v205 adds a separate bilingual forms layer without deleting the existing Forms & Notices module.

### Bilingual templates
1. Notice for Appearance before Police — Sec. 35(3) BNSS
2. Arrest Memorandum — supplied BNSS reference structure
3. Notice / Written Order to Produce Document or Thing — Sec. 94 BNSS
4. Notice to Witness for Attendance — Sec. 179 BNSS
5. Personal Search Memorandum — Sec. 49 BNSS
6. Medical Examination Requisition
7. FSL Forwarding Letter / Examination Requisition
8. Investigation Progress Intimation — Sec. 193(3)(ii) BNSS

Every template can be created separately in English or Bengali. Case number, case date, sections, police station, district, officer data, complainant/accused data and FIR gist are auto-filled only where the source field logically supports them. Officer must review/edit facts before Final Save.

## Source discipline
- Supplied `BNSS several types of notices.pdf` is used as the field/layout/reference source.
- Enacted BNSS numbering is verified separately through authoritative law source data used by v204 Legal Search.
- The medical examination reference form in the supplied source does not specify a BNSS section; v205 deliberately does not invent one.
- The arrest memorandum source contains an unlabeled numbered row 5; v205 preserves that gap instead of guessing its label.
- Bengali wording is an INVESTIGO helper rendition and is not labelled as an authenticated official statutory translation unless such a source is separately integrated.

## CD integration
On Final Save, existing FormEditor confirmation remains active. If the officer selects `Mention in Case Diary = Yes`, v205 generates a form-specific PendingCdAction, e.g. service of Sec. 35(3) notice, issue of Sec. 179 witness notice, Sec. 94 document-production order, personal-search memo, medical requisition, FSL forwarding, or Sec. 193(3)(ii) progress communication.

## Law Search integration
Templates with a known BNSS section show a Law Search shortcut. Templates without a source-supported BNSS section do not show a fabricated law reference.

## Compatibility
No SQLite migration. Bilingual form choice is encoded in FormNotice.templateId using `__en` or `__bn`, so existing saved FormNotice JSON remains compatible.
