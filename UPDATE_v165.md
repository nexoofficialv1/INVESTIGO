# INVESTIGO v1.6.5

- Added the missing SmartCaseService required by Investigation Assistant.
- Added speech_to_text dependency required by the existing voice input screen.
- PO Visit, Sketch Map, Index, FIR receipt and complainant examination are normally-once actions.
- A repeated normally-once action requires an officer-entered justification.
- Witness examination, raid/search, arrest, seizure and requisition remain repeatable.
- Narration suggestions now carry action-specific detected time and place.
- Bengali/English witness count and witness-name extraction improved.
- Detected place/time populate the assistant fields when blank.
- Added automated tests for duplicate rules and witness extraction.
