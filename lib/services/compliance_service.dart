import '../models/case_file.dart';
import 'sop_compliance_service.dart';

class ComplianceTask {
  final String title;
  final String detail;
  final String priority;
  final bool mandatory;

  const ComplianceTask({
    required this.title,
    required this.detail,
    required this.priority,
    required this.mandatory,
  });
}

class ComplianceService {
  List<ComplianceTask> buildTasks(CaseFile caseFile) {
    final sections = caseFile.sections.toLowerCase();
    final tasks = <ComplianceTask>[
      const ComplianceTask(
        title: 'CD continuity',
        detail: 'Every CD must start with fixed opening and end with fixed closing line.',
        priority: 'High',
        mandatory: true,
      ),
      const ComplianceTask(
        title: 'Witness statement u/s 180 BNSS',
        detail: 'Record available complainant/victim/local/eye/seizure witness statements.',
        priority: 'High',
        mandatory: true,
      ),
      const ComplianceTask(
        title: 'Rough sketch map with index',
        detail: 'Prepare or update rough sketch map if PO visit is material.',
        priority: 'Medium',
        mandatory: false,
      ),
      const ComplianceTask(
        title: 'Medical/BHT/Injury papers',
        detail: 'Collect medical papers wherever assault, injury, poisoning, death or sexual offence is involved.',
        priority: 'Medium',
        mandatory: false,
      ),
    ];

    if (sections.contains('pocso') || sections.contains('74') || sections.contains('75') || sections.contains('69')) {
      tasks.addAll(const [
        ComplianceTask(
          title: 'Victim statement u/s 183 BNSS',
          detail: 'Generate 183 BNSS prayer and track court statement recording.',
          priority: 'High',
          mandatory: true,
        ),
        ComplianceTask(
          title: 'Age proof / birth certificate',
          detail: 'Collect school certificate, birth certificate or other age proof where victim/minor issue exists.',
          priority: 'High',
          mandatory: true,
        ),
        ComplianceTask(
          title: 'Medical examination of victim',
          detail: 'Generate medical requisition and collect report/BHT.',
          priority: 'High',
          mandatory: true,
        ),
      ]);
    }

    if (sections.contains('109') || sections.contains('115') || sections.contains('117') || sections.contains('118')) {
      tasks.addAll(const [
        ComplianceTask(
          title: 'Injury report verification',
          detail: 'Collect injury report/BHT and mention injuries in CD.',
          priority: 'High',
          mandatory: true,
        ),
        ComplianceTask(
          title: 'Weapon/article seizure check',
          detail: 'If weapon/article used, prepare seizure list and consider FSL.',
          priority: 'Medium',
          mandatory: false,
        ),
      ]);
    }

    if (sections.contains('318') || sections.contains('319') || sections.contains('316') || sections.contains('cyber') || sections.contains('bank')) {
      tasks.addAll(const [
        ComplianceTask(
          title: 'Bank/UPI transaction trail',
          detail: 'Generate bank requisition for KYC, statement, beneficiary, UTR and lien/freeze details.',
          priority: 'High',
          mandatory: true,
        ),
        ComplianceTask(
          title: 'Digital evidence certificate',
          detail: 'Track electronic records and certificate requirement under BSA as applicable.',
          priority: 'High',
          mandatory: true,
        ),
      ]);
    }

    if (sections.contains('303') || sections.contains('305') || sections.contains('306') || sections.contains('309') || sections.contains('317')) {
      tasks.addAll(const [
        ComplianceTask(
          title: 'Stolen/recovered property list',
          detail: 'Maintain property list, seizure list and recovery memo details.',
          priority: 'High',
          mandatory: true,
        ),
        ComplianceTask(
          title: 'Malkhana entry',
          detail: 'Ensure seized/recovered property is linked with malkhana reference.',
          priority: 'Medium',
          mandatory: false,
        ),
      ]);
    }

    final sopRules = SopComplianceService().buildRules(caseFile);
    for (final rule in sopRules.where((r) => r.mandatory)) {
      tasks.add(ComplianceTask(
        title: 'SOP: ${rule.title}',
        detail: '${rule.sectionRef} • ${rule.detail}',
        priority: 'High',
        mandatory: true,
      ));
    }

    tasks.add(const ComplianceTask(
      title: 'CS/FR pre-check',
      detail: 'Before final report, generate CS/FR checklist from Forms module and confirm SOP compliance.',
      priority: 'Medium',
      mandatory: true,
    ));

    return tasks;
  }
}
