import '../models/case_file.dart';
import '../models/officer_profile.dart';

class FormTemplateInfo {
  final String id;
  final String title;
  final String subtitle;
  final String category;

  const FormTemplateInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
  });
}

class FormsGeneratorService {
  static const List<FormTemplateInfo> templates = [
    FormTemplateInfo(id: 'bnss_35_3', title: '35(3) BNSS Notice', subtitle: 'Accused/person appearance and cooperation notice', category: 'Notice'),
    FormTemplateInfo(id: 'bnss_94', title: '94 BNSS Requisition', subtitle: 'Document / thing production requisition', category: 'Requisition'),
    FormTemplateInfo(id: 'bnss_183', title: '183 BNSS Prayer', subtitle: 'Judicial statement prayer before Ld. Court', category: 'Court Prayer'),
    FormTemplateInfo(id: 'medical_exam', title: 'Medical Examination Requisition', subtitle: 'Victim/injured/accused medical examination', category: 'Medical'),
    FormTemplateInfo(id: 'bht_injury', title: 'BHT / Injury Report Requisition', subtitle: 'Hospital records and injury report collection', category: 'Medical'),
    FormTemplateInfo(id: 'cdr_caf', title: 'CDR / SDR / CAF Requisition', subtitle: 'Official table format for CDR/SDR/CAF/IMEI request', category: 'Digital Evidence'),
    FormTemplateInfo(id: 'bank_details', title: 'Bank Account Details Requisition', subtitle: 'Account statement/KYC/lien/freeze details', category: 'Cyber/Bank'),
    FormTemplateInfo(id: 'fsl', title: 'FSL Form + Challan + Label Package', subtitle: 'WB Form 5203 with exhibit list, challan and labels', category: 'Expert'),
    FormTemplateInfo(id: 'forwarding', title: 'Accused Forwarding Report', subtitle: 'Forwarding accused before Ld. Court', category: 'Court'),
    FormTemplateInfo(id: 'further_investigation', title: 'Further Investigation Prayer', subtitle: 'Prayer for further investigation/extension/compliance', category: 'Court Prayer'),
    FormTemplateInfo(id: 'cs_checklist', title: 'CS / FR Draft Checklist', subtitle: 'Pre-submission checklist for charge sheet/final report', category: 'Final Report'),
  ];

  FormTemplateInfo templateById(String id) {
    return templates.firstWhere(
      (e) => e.id == id,
      orElse: () => templates.first,
    );
  }

  String generate({
    required String templateId,
    required OfficerProfile officer,
    required CaseFile caseFile,
  }) {
    switch (templateId) {
      case 'bnss_35_3':
        return _notice35(officer, caseFile);
      case 'bnss_94':
        return _requisition94(officer, caseFile);
      case 'bnss_183':
        return _prayer183(officer, caseFile);
      case 'medical_exam':
        return _medicalExam(officer, caseFile);
      case 'bht_injury':
        return _bhtInjury(officer, caseFile);
      case 'cdr_caf':
        return _cdrCaf(officer, caseFile);
      case 'bank_details':
        return _bankDetails(officer, caseFile);
      case 'fsl':
        return _fsl(officer, caseFile);
      case 'forwarding':
        return _forwarding(officer, caseFile);
      case 'further_investigation':
        return _furtherInvestigation(officer, caseFile);
      case 'cs_checklist':
        return _csChecklist(officer, caseFile);
      default:
        return _generic(officer, caseFile);
    }
  }

  String _caseRef(OfficerProfile officer, CaseFile caseFile) {
    return '${officer.policeStation} PS Case No. ${caseFile.psCaseNo} dated ${caseFile.caseDate} u/s ${caseFile.sections}';
  }

  String _valueOrBlank(String value, String fallback) => value.trim().isEmpty ? fallback : value.trim();

  String _notice35(OfficerProfile officer, CaseFile caseFile) {
    final accused = _valueOrBlank(caseFile.accusedName, '____________________________');
    return '''NOTICE OF APPEARANCE BY THE POLICE
[As per section – 35 (3) BNSS Act.]

Serial No.............                                                   Annexure-A

To,
1. $accused

In exercise of the powers conferred under section 35 (3) of BNSS, I hereby inform you that during the investigation of FIR/Case No ${_caseRef(officer, caseFile)}, it is revealed that there are reasonable grounds to question you to ascertain facts and circumstances from you, in relation to the present investigation. Hence you are directed to appear before undersigned officer within 03 (three) days after receiving the notice at ________ AM/PM at ${officer.policeStation}, Dist-${officer.district}.

You are directed to comply with all and/or the following directions:-
a) You will not commit any offence in future.
b) You will not tamper with the evidences in the case in any manner whatsoever.
c) You will not make any threat, inducement, or promise to any person acquainted with the fact of the case so as to dissuade him/her from disclosing such facts to the court or to police officer.
d) You will appear before the Court as and when required/directed.
e) You will join the investigation of the case as and when required and will cooperate in the investigation.
f) You will disclose all the facts truthfully without concealing any part relevant for the purpose of investigation to reach to the right conclusion of the case.
g) You will produce all relevant documents/material required for the purpose of investigation.
h) You will render your full co-operation/assistance in apprehension of the accomplice.
i) You will not allow in any manner destruction of any evidence relevant for the purpose of investigation/trial of the case.
j) Any other conditions, which may be imposed by the Investigating Officer / Officer-in-Charge as per the facts of the case.

Failure to attend/comply with the terms of this Notice can render you liable for arrest under Section 35 (6) BNSS.''';
  }

  String _requisition94(OfficerProfile officer, CaseFile caseFile) {
    final complainant = _valueOrBlank(caseFile.complainantName, 'the complainant');
    return '''NOTICE U/S 94 BNSS, 2023

To
The Superintendent / Officer-in-Charge,
____________________________
P.S. ______________________
District – __________________.

Ref: ${officer.policeStation} Case No- ${caseFile.psCaseNo} Dated-${caseFile.caseDate}, U/S- ${caseFile.sections}.

Whereas an investigation is being conducted in c/w above reference and whereas the records/documents/articles relating to complainant/informant $complainant and the above noted case are required for the purpose of proper investigation, you are hereby requested under the provisions of Section 94 of the BNSS, 2023, to produce and/or furnish the following documents/information:

1. Admission Register Entry / relevant register entry.
2. OPD/IPD tickets and complete treatment/official records.
3. Case history sheet / Bed Head Ticket / connected documents, if maintained.
4. Examination report / treatment records / relevant certificate, if prepared.
5. Name, designation and particulars of the concerned officers/persons.
6. Age-related documents and records available, if any.
7. Reports, forms and requisition papers, if any.
8. Copies of all relevant documents, records and reports.
9. Any other document, record or report relevant to the investigation.

You are requested to provide the aforesaid documents, duly attested, at the earliest for the purpose of investigation.

Failure to comply with this notice without lawful excuse may attract legal consequences as prescribed under law.''';
  }

  String _prayer183(OfficerProfile officer, CaseFile caseFile) => '''In the Court of ${officer.courtName}

Sub: Prayer for recording statement u/s 183 BNSS in connection with ${_caseRef(officer, caseFile)}.

May it please your honour,
Most respectfully I beg to submit that during investigation of the above noted case, it is necessary to record the statement of the victim/witness namely ____________________ u/s 183 BNSS for the purpose of fair and proper investigation.

It is therefore prayed before your honour to kindly allow recording of the statement of the said victim/witness u/s 183 BNSS.

Submitted by,

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}''';

  String _medicalExam(OfficerProfile officer, CaseFile caseFile) => '''To,
The Medical Officer,
____________________________ Hospital

Sub: Medical examination requisition in connection with ${_caseRef(officer, caseFile)}.

Sir/Madam,
The person named ____________________, S/O/W/O ____________________, address ____________________, is being sent for medical examination in connection with the above noted case.

Kindly examine the said person and furnish the injury report/medical examination report at the earliest for the purpose of investigation.

Yours faithfully,

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}''';

  String _bhtInjury(OfficerProfile officer, CaseFile caseFile) => '''To,
The Superintendent / Medical Officer,
____________________________ Hospital

Sub: Requisition for BHT / injury report / treatment papers in connection with ${_caseRef(officer, caseFile)}.

Sir/Madam,
It is requested to provide certified copy of BHT/injury report/treatment papers of ____________________, who was treated/admitted at your hospital on __________ in connection with the above noted case.

The said medical papers are urgently required for investigation.

Yours faithfully,

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}''';

  String _cdrCaf(OfficerProfile officer, CaseFile caseFile) {
    final ref = '${officer.policeStation} P.S. Case No-${caseFile.psCaseNo} Dated-${caseFile.caseDate}, U/S-${caseFile.sections}';
    final gist = caseFile.firGist.trim().isEmpty ? '____________________________________________________________________________________________' : caseFile.firGist.trim();
    return """CDR/SDR/CAF STRUCTURED ENTRY

CASE REFERENCE: $ref
GIST: $gist
REQUIRED MOBILE/IMEI: ________________________________
ACTUAL USER / INVOLVEMENT: Used by suspected / ________________________________
JUSTIFICATION: To trace out / verify / identify ________________________________
CDR DATE RANGE: From ____________ To ____________
SDR REQUIRED: Yes
CAF REQUIRED: Yes
IMEI SEARCH DATE RANGE: ---
IO NAME: ${officer.rank} ${officer.name}
IO PHONE: ${officer.mobile}
ANY OTHER POINTS: N/A

Note: Fill the above entry fields. Preview will render the official table format.""";
  }

  String _bankDetails(OfficerProfile officer, CaseFile caseFile) => '''To,
The Branch Manager / Nodal Officer,
____________________________ Bank

Sub: Requisition for bank account details in connection with ${_caseRef(officer, caseFile)}.

Sir/Madam,
It is requested to provide the following details in respect of Account No./UPI ID ____________________ for the purpose of investigation:

1. Account holder name, address, mobile number and KYC documents.
2. Statement of account from __________ to __________.
3. Details of disputed transaction(s), beneficiary account and UTR.
4. Present balance and lien/freeze status, if any.
5. Any other linked account/UPI/mobile/email details.

Yours faithfully,

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}''';

  String _fsl(OfficerProfile officer, CaseFile caseFile) {
    final gist = caseFile.firGist.trim().isEmpty ? 'The fact of the case in brief is that ________________________________________________________________________________.' : caseFile.firGist.trim();
    return """FSL PACKAGE STRUCTURED ENTRY

NATURE OF CRIME: $gist
EXHIBIT DESCRIPTION: Exhibit Mark "A" ---- One sealed packet/jar/container containing said to be ________________________________ in connection with the above noted case.
HOW FOUND / SEIZED: Seized on ____________ at ________________________________ by ${officer.rank} ${officer.name} / received from ________________________________.
NATURE OF EXAMINATION: 1) Whether any poison / blood / semen / biological material / chemical / explosive / narcotic / digital trace / other relevant material could be detected in Exhibit Mark "A" or not.\n2) If detected, nature/type/source of such material and whether the same is relevant to the facts of the case.\n3) Any other points raised during examination.
PERSON IN CUSTODY: ________________________________
FSL OFFICE: Head of Office & Assistant Director\nRegional Forensic Science Laboratory\nShankarpur, Durgapur\nPaschim Bardhaman, 713212
COURT: Ld. C.J.M / Magistrate, ${officer.district}

Note: Fill the above entry fields. Preview will generate Form 5203 + Exhibit List + Examination Required + Custody + Magistrate forwarding/certification + Challan + Labels.""";
  }

  String _forwarding(OfficerProfile officer, CaseFile caseFile) => '''Ref:   ${officer.policeStation} case no- ${caseFile.psCaseNo} Dated: - ${caseFile.caseDate} u/s - ${caseFile.sections}.

Sub:   Forwarding of FIR named arrested accused person namely- ____________________________.

Sir,
        In forwarding herewith the arrested accused person namely- ____________________________ S/O- ____________________________ of ____________________________, P.S.- ____________________, Dist.- ____________________ before your honour's court with all connected paper and proper Police escort I beg to report that on __________ at ______ hrs received a written complaint from one ${caseFile.complainantName.isEmpty ? '____________________' : caseFile.complainantName} to the effect that ${caseFile.firGist.isEmpty ? '____________________________________________________________________________' : caseFile.firGist}. Over this complaint the above referred case has been started and as per endorsement I took up its investigation.

        During investigation I visited the PO, prepared rough sketch map of the PO with its index in separate sheets of paper. Examined the complainant and other available witnesses and recorded their statements u/s-180 BNSS in separate sheets of paper. Thereafter the FIR named accused person was arrested after observing all legal formalities. The grounds of arrest have been informed to the accused person and his/her family member in their vernacular language and a copy of the same was served upon them.

        Under the above fact and circumstances, I therefore pray before your Honour's court that arrested accused person namely- ____________________________ may kindly be taken in judicial custody / police custody as prayed for till investigation is over. I strongly oppose bail on the following grounds:-

(1) The case is in green stage of investigation. If released on bail at this stage, the accused may hamper the investigation.
(2) Many important witnesses are yet to be examined. If released on bail at this stage, the accused may induce witnesses.
(3) Police custody / further interrogation may be required for the purpose of investigation.''';

  String _furtherInvestigation(OfficerProfile officer, CaseFile caseFile) => '''In the Court of ${officer.courtName}

Sub: Prayer for further investigation/compliance in connection with ${_caseRef(officer, caseFile)}.

May it please your honour,
Most respectfully I beg to submit that further investigation/compliance is required in the above noted case for the following reasons:

1. ______________________________________
2. ______________________________________
3. ______________________________________

It is therefore prayed before your honour to kindly allow/permit the undersigned to proceed with the necessary investigation/compliance.

Submitted by,

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}''';

  String _csChecklist(OfficerProfile officer, CaseFile caseFile) => '''CS / FR PRE-SUBMISSION CHECKLIST

Case Reference: ${_caseRef(officer, caseFile)}
IO: ${officer.rank} ${officer.name}

[ ] FIR / Formal FIR attached
[ ] Original complaint attached
[ ] Rough sketch map with index attached
[ ] Statements u/s 180 BNSS attached
[ ] Judicial statement u/s 183 BNSS, if any, attached
[ ] Medical / injury / BHT / PM report attached, if applicable
[ ] Seizure list and malkhana reference attached, if applicable
[ ] FSL / expert report attached, if applicable
[ ] CDR/CAF/bank/digital evidence attached, if applicable
[ ] Arrest memo / forwarding / custody papers attached, if applicable
[ ] Accused particulars verified
[ ] Witness list prepared
[ ] Property list prepared
[ ] 230 BNSS indexed copy supply checklist prepared
[ ] Final opinion / CS or FR ground prepared

Remarks:
______________________________________
______________________________________

Prepared by,
${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}''';

  String _generic(OfficerProfile officer, CaseFile caseFile) => '''Reference: ${_caseRef(officer, caseFile)}

Draft details:
______________________________________
______________________________________
______________________________________

${officer.rank} ${officer.name}
Investigating Officer
${officer.policeStation}''';
}
