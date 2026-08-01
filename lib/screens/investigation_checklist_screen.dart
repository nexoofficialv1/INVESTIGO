import 'package:flutter/material.dart';

import '../models/case_file.dart';

class InvestigationChecklistScreen extends StatefulWidget {
  final CaseFile caseFile;

  const InvestigationChecklistScreen({super.key, required this.caseFile});

  @override
  State<InvestigationChecklistScreen> createState() => _InvestigationChecklistScreenState();
}

class _InvestigationChecklistScreenState extends State<InvestigationChecklistScreen> {
  final Set<String> _checked = <String>{};

  @override
  Widget build(BuildContext context) {
    final sections = _buildChecklist(widget.caseFile);
    final total = sections.fold<int>(0, (sum, sec) => sum + sec.items.length);
    return Scaffold(
      appBar: AppBar(title: const Text('Investigation Checklists')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.caseFile.displayTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('Sections: ${widget.caseFile.sections}'),
                  const SizedBox(height: 8),
                  Text('Checked: ${_checked.length} / $total', style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text(
                    'প্রতিটা item tap করলে tick/untick হবে। CD/IF5 final করার আগে এগুলো verify করুন।',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...sections.map((section) => _ChecklistBlock(
                section: section,
                checked: _checked,
                onToggle: (item, value) {
                  setState(() {
                    if (value) {
                      _checked.add(item);
                    } else {
                      _checked.remove(item);
                    }
                  });
                },
              )),
          const SizedBox(height: 70),
        ],
      ),
    );
  }

  List<_ChecklistSection> _buildChecklist(CaseFile file) {
    final lower = file.sections.toLowerCase();
    final pocso = lower.contains('pocso');
    final hurt = lower.contains('115') || lower.contains('117') || lower.contains('118') || lower.contains('109');
    final property = lower.contains('303') || lower.contains('305') || lower.contains('309') || lower.contains('317') || lower.contains('318');

    final common = <_ChecklistSection>[
      _ChecklistSection('Case Starting / Basic Documents', [
        'Written complaint / FIR copy verified',
        'Formal FIR / PS case details verified',
        'IO endorsement and took-up date noted',
        'PO, DO, DR, DD, DA, RO and IO details entered',
        'Complainant / victim / accused basic details entered',
      ]),
      _ChecklistSection('PO Visit & Local Enquiry', [
        'Visited PO and noted exact location',
        'Prepared rough sketch map with index if required',
        'Important landmarks / boundary / surrounding noted',
        'Local witnesses identified and examined',
        'CCTV / nearby shop / public source checked if relevant',
      ]),
      _ChecklistSection('Statements', [
        'Complainant statement u/s 180 BNSS',
        'Victim statement u/s 180 BNSS',
        'Available witnesses statement u/s 180 BNSS',
        'Seizure witnesses statement if seizure made',
        'Contradictory / hostile / no-knowledge witness noted separately if any',
      ]),
      _ChecklistSection('Accused / Suspect Action', [
        'Accused particulars verified',
        'Notice u/s 35 BNSS / arrest action updated as applicable',
        'Ground of arrest / family intimation / medical if arrested',
        'Forwarding / PC-JC prayer / bail status updated',
        'Previous case / conviction / local reputation verified if needed',
      ]),
      _ChecklistSection('Evidence / Seizure / Digital Evidence', [
        'Seizure list prepared where applicable',
        'Malkhana / property register details noted',
        'FSL / expert opinion requisition if needed',
        'CDR / CAF / bank / UPI / CCTV requisition if needed',
        'Electronic evidence certificate u/s 63(4) BSA considered if required',
      ]),
      _ChecklistSection('SOP Mandatory Checks', [
        'If information received electronically, informant signature obtained within 3 days',
        'PO photography/videography recorded where applicable u/s 176(3) BNSS',
        'For serious offence punishable over 7 years, forensic expert call/requirement checked',
        'Victim/informant progress/result intimation within 90 days tracked',
        'If investigation not concluded within 90 days, extension prayer before expiry prepared',
        'If electronic device/evidence involved, sequence/chain of custody maintained',
      ]),
      _ChecklistSection('Final Stage / IF5 Preparation', [
        'All CDs reviewed up to final investigation CD',
        'Final CD contains total investigation summary',
        'Witness list ready for IF5',
        'Accused charge-sheeted / not charge-sheeted list ready',
        'Enclosures list prepared',
        'Informant/victim informed about result/progress as applicable',
        'SOP Compliance screen verified before final report',
      ]),
    ];

    if (pocso) {
      common.insert(3, _ChecklistSection('POCSO / Minor / Victim Related', [
        'Victim age proof / school record / birth certificate collected',
        'Medical examination / consent / refusal details recorded',
        '183 BNSS judicial statement prayer and result updated',
        'Guardian / family member statement recorded',
        'Special Court / JJB compliance checked as applicable',
      ]));
    }
    if (hurt) {
      common.insert(3, _ChecklistSection('Medical / Injury Related', [
        'Injury report / BHT / discharge certificate requisitioned',
        'Doctor / MO details noted',
        'Weapon / cause of injury angle verified',
        'Medical papers attached in final record',
      ]));
    }
    if (property) {
      common.insert(4, _ChecklistSection('Property / Fraud / Recovery Related', [
        'Stolen/cheated property details verified',
        'Recovery/seizure details with witnesses',
        'Bank/UPI/account trail requisition if financial fraud',
        'Ownership documents / invoice / valuation collected if needed',
      ]));
    }
    return common;
  }
}

class _ChecklistBlock extends StatelessWidget {
  final _ChecklistSection section;
  final Set<String> checked;
  final void Function(String item, bool value) onToggle;

  const _ChecklistBlock({required this.section, required this.checked, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(section.title, style: const TextStyle(fontWeight: FontWeight.w900)),
        children: section.items.map((item) {
          final key = '${section.title}::$item';
          return CheckboxListTile(
            value: checked.contains(key),
            onChanged: (value) => onToggle(key, value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(item),
            dense: true,
          );
        }).toList(),
      ),
    );
  }
}

class _ChecklistSection {
  final String title;
  final List<String> items;
  _ChecklistSection(this.title, this.items);
}
