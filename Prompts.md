# INVESTIGO Prompts and Offline Drafting Rules

## Scope
The first release uses deterministic offline parsing, not a public online AI service. Case data remains on the device.

## Regular Case narration
The officer may narrate actions in Bengali or English. The parser proposes separate entries containing:
- time
- place
- synopsis
- proceedings
- detected action type

Rules:
- PO Visit is normally once; a repeat requires a reason.
- Sketch Map and Index are normally once and remain separate documents.
- Witness statements are repeatable.
- Arrest, seizure, raid, search and follow-up requisitions may repeat for different subjects/items.
- Suggestions are never final without officer approval.

## UD narration
UD narration may populate draft facts for Inquest/Surathal, Dead Body Challan and Final Report. The system must display extracted facts and missing fields before export.

## Language
Translation changes text only. Locked layout, line position, column count, page orientation and signature block remain unchanged.

## Future online AI
Optional only. Before any request, identifying data must be masked; API keys must never be embedded in the APK. The returned draft must still require officer approval.

## Sketch map trigger
When narration indicates that a rough sketch map was prepared, the assistant may offer to open the separate Sketch Map editor. It must not silently add a map to the CD bundle.

## Final-document drafting boundary

Offline drafting may summarize approved regular-case CD rows into Final CD,
Charge Sheet and IF-5 drafts. It must not read UD or NCR records. Draft output
must preserve facts, show missing fields, and remain editable. No final
document becomes approved automatically.

## Final document drafting boundary
Offline narration may propose investigation text, but Final CD, Charge Sheet and IF-5 remain separate officer-reviewed drafts. Generated text must never mark any document approved.

## Final-document drafting boundary
Offline drafting may suggest narrative text only. It must not fabricate charge-sheet number, court, laboratory result, accused status or dispatch data; those require officer review.


## v1.7.6
No narration prompt change. Feature-freeze metadata must never alter officer narration or generated document content.

## Profile binding rule
Generated drafts must never invent a Police Station or District. Use the saved OfficerProfile and block export when PS/District are missing.

## v185
No prompt change. Official FSL/A Form exports do not use generative AI.

## RC-1 assistant constraint

Offline assistant output must never invent Police Station or District. Document identity fields come exclusively from the current Officer Profile. Generated CD text may propose investigation actions, but official row metadata remains officer-editable before approval.

## RC-1 v189 — CD output rule
When generating Form 5363, preserve each investigation action as an individual `CdTableLine`, but render all actions inside one continuous four-column body without horizontal action separators. Never derive the form year from the device clock when a case year is available.

## UD smart narration guidance

For best extraction, officers may write natural sentences or use labels such as `UD No`, `GDE No`, `Name of deceased`, `Place where dead body found`, `Body position`, `Dress`, `Probable cause of death`, `Witness 1` and `Witness 2`. The full narration is always retained as `briefFacts` for verification.

## v194 Translation Rule

Attempt target-language translation, but never block official document access. Preserve original entered text when the model is unavailable.

<!-- v195-desktop-foundation -->
## v195 desktop prompt policy

No official-document generation prompt was changed. Desktop uses the same
bilingual labels, locked templates, user-entered facts and preview/PDF/DOC
pipeline as mobile. Platform-specific UI instructions must never alter legal
facts or template text.

## v204
No generative prompt is allowed to rewrite statutory text as if it were official. Any helper translation/explanation must remain visibly labelled as assistive.

## v205
No generative model may fabricate form facts, service status, arrest grounds, witness details, seized items, medical findings or FSL results. Templates provide structure only; the officer supplies and validates case facts.

## v206
Form drafting is deterministic from officer-entered structured facts. Any assisted drafting must preserve explicit user facts and must not promote helper Bengali wording to authenticated statutory translation.

## v207 — Guided input
UI guidance may simplify wording but must not change the evidentiary meaning of officer-entered facts or generate investigative acts that were not supplied.

## v208
Draft/report prompts must use only supplied facts. Never auto-write “no foul play”, “visited PO”, “witnesses examined”, “inquest held”, “PM conducted”, or equivalent unless the corresponding officer-confirmed record exists.

## v208.1
Do not rewrite official UD form layouts. Data assistance may populate existing fields only. Any conclusion about foul play must come from the explicit officer selection; PM cause of death must come from the entered PM Report.

