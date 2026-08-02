# INVESTIGO Prompts and Drafting Rules

## Scope
The first release uses an offline rule-based narration parser. It is not allowed to present generated text as verified fact or final police writing without officer review.

## Input modes
- Manual Bengali or English text.
- Device speech-to-text converted to editable text.
- No case narration is sent to an online AI service in the first release.

## Output contract
For every detected action, the assistant should propose:
- date/time
- place of entry
- synopsis
- proceedings/main body
- action type
- repeatability rule
- missing-field warnings
- source narration reference

The officer may edit, deselect, or approve each proposal separately.

## CD drafting rules
- Do not repeat the entire narration in every CD row.
- Split distinct actions into distinct official rows.
- CD-1 may contain FIR receipt, complainant/witness examination, PO visit, sketch map/index reference, raid/search, arrest, seizure and requisitions as applicable.
- Later CDs may contain additional witness statements and follow-up actions.
- A second PO visit requires a reason such as verification, measurement, recovery/search, or new information.
- Witness statements remain repeatable.
- Do not invent time, place, witness identity, section, injury, recovery, arrest, or result.

## UD drafting rules
Shared facts may populate Inquest/Surathal, Dead Body Challan and UD Final Report, but each document must have its own editable draft. The parser must not infer a cause of death beyond the officer/medical source text.

## Language rules
- Preserve user-entered names, addresses, sections and numbers.
- Bengali and English are display/drafting modes; switching language must not silently translate legal facts incorrectly.
- Official form wording is template-locked where a reference is supplied.

## Future online AI
Online AI is deferred and optional. Before implementation it requires masking, encryption, an approved provider/private server, consent/configuration, audit logging and officer approval. API keys must never be embedded in the APK.

## Change rule
Any parser keyword, extraction rule, generated paragraph, online prompt, masking rule, or approval behavior must update this file and its tests.
