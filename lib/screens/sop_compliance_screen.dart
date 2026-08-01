import 'package:flutter/material.dart';

import '../models/case_file.dart';
import '../services/sop_compliance_service.dart';

class SopComplianceScreen extends StatefulWidget {
  final CaseFile caseFile;
  const SopComplianceScreen({super.key, required this.caseFile});

  @override
  State<SopComplianceScreen> createState() => _SopComplianceScreenState();
}

class _SopComplianceScreenState extends State<SopComplianceScreen> {
  final Set<String> _done = <String>{};

  @override
  Widget build(BuildContext context) {
    final rules = SopComplianceService().buildRules(widget.caseFile);
    final grouped = <String, List<SopRule>>{};
    for (final r in rules) {
      grouped.putIfAbsent(r.category, () => <SopRule>[]).add(r);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('SOP Compliance')),
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
                  const SizedBox(height: 4),
                  Text('Sections: ${widget.caseFile.sections}'),
                  const SizedBox(height: 8),
                  Text('SOP checked: ${_done.length} / ${rules.length}', style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text(
                    'Uploaded SOP অনুযায়ী mandatory investigation prompts. প্রতিটি item verify করে tick করুন; relevant document/CD entry later link করা যাবে.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...grouped.entries.map((entry) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w900)),
                  children: entry.value.map((rule) {
                    final key = '${entry.key}::${rule.title}';
                    return CheckboxListTile(
                      value: _done.contains(key),
                      onChanged: (value) {
                        setState(() {
                          if (value ?? false) {
                            _done.add(key);
                          } else {
                            _done.remove(key);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      secondary: Icon(rule.mandatory ? Icons.priority_high_rounded : Icons.info_outline_rounded),
                      title: Text(rule.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${rule.sectionRef}\n${rule.detail}'),
                      isThreeLine: true,
                    );
                  }).toList(),
                ),
              )),
          const SizedBox(height: 70),
        ],
      ),
    );
  }
}
