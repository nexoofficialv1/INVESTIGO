import 'package:flutter/material.dart';

import '../models/officer_profile.dart';
import '../models/ud_case.dart';
import '../models/ud_lifecycle.dart';
import '../services/local_store_service.dart';
import '../services/ud_lifecycle_document_service.dart';
import '../services/ud_lifecycle_store.dart';
import '../services/ud_lifecycle_validation_service.dart';
import '../widgets/investigo_ui.dart';
import 'pdf_preview_screen.dart';

class UdCaseWorkflowScreen extends StatefulWidget {
  final OfficerProfile profile;

  const UdCaseWorkflowScreen({super.key, required this.profile});

  @override
  State<UdCaseWorkflowScreen> createState() => _UdCaseWorkflowScreenState();
}

class _UdCaseWorkflowScreenState extends State<UdCaseWorkflowScreen> {
  final _store = LocalStoreService();
  final _flowStore = UdLifecycleStore();
  final _validator = const UdLifecycleValidationService();
  final _documents = UdLifecycleDocumentService();

  List<UdCase> _uds = [];
  Map<String, UdLifecycleRecord> _flows = {};
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uds = await _store.loadUdCases();
    final flows = await _flowStore.loadAll();
    if (!mounted) return;
    setState(() {
      _uds = uds;
      _flows = flows;
      if (_selectedId == null && uds.isNotEmpty) _selectedId = uds.first.id;
      if (_selectedId != null && !uds.any((e) => e.id == _selectedId)) {
        _selectedId = uds.isEmpty ? null : uds.first.id;
      }
    });
  }

  UdCase? get _selectedUd {
    for (final ud in _uds) {
      if (ud.id == _selectedId) return ud;
    }
    return null;
  }

  UdLifecycleRecord _flowFor(UdCase ud) =>
      _flows[ud.id] ?? UdLifecycleRecord.empty(ud.id);

  Future<void> _saveFlow(UdLifecycleRecord flow) async {
    await _flowStore.save(flow);
    await _load();
  }

  Future<void> _saveUd(UdCase ud) async {
    await _store.saveUdCase(ud);
    await _load();
  }

  Future<String?> _pickDate(String current) async {
    final initial = DateTime.tryParse(current) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked == null) return null;
    return '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
  }

  Future<String?> _pickTime(String current) async {
    final parts = current.split(':');
    final initial = parts.length == 2
        ? TimeOfDay(
            hour: int.tryParse(parts[0]) ?? TimeOfDay.now().hour,
            minute: int.tryParse(parts[1]) ?? TimeOfDay.now().minute,
          )
        : TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showErrors(UdValidationResult result) async {
    if (result.errors.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('এই তথ্যগুলো দিন'),
        content: Text('• ${result.errors.join('\n• ')}'),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('ঠিক আছে'))],
      ),
    );
  }

  Future<bool> _confirmWarnings(UdValidationResult result) async {
    if (result.warnings.isEmpty) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('তারিখ যাচাই করুন'),
        content: Text('• ${result.warnings.join('\n• ')}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ফিরে যান')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('তারিখ সঠিক')),
        ],
      ),
    );
    return ok == true;
  }

  TextEditingController _c(String value) => TextEditingController(text: value);

  Widget _field(TextEditingController controller, String label, {int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          maxLines: lines,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
      );

  Widget _picker({
    required String label,
    required String value,
    required bool time,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFD9DFEA)),
        ),
        leading: Icon(time ? Icons.schedule_outlined : Icons.calendar_month_outlined, color: InvestigoUi.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(value.trim().isEmpty ? 'চাপ দিয়ে নির্বাচন করুন' : value),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () async {
          final picked = time ? await _pickTime(value) : await _pickDate(value);
          if (picked != null) onChanged(picked);
        },
      ),
    );
  }

  Future<void> _newUd() async {
    final ud = UdCase.empty(ps: widget.profile.policeStation, district: widget.profile.district);
    await _editRegistration(ud, isNew: true);
  }

  Future<void> _editRegistration(UdCase ud, {bool isNew = false}) async {
    final udNo = _c(ud.udNo);
    final gde = _c(ud.gdeNo);
    final registration = _c(ud.dateTime);
    final place = _c(ud.placeFound);
    final informant = _c(ud.informantName);
    final informantAddress = _c(ud.informantAddress);
    final deceased = _c(ud.deceasedName);
    final deceasedAge = _c(ud.deceasedAge);
    final deceasedSex = _c(ud.deceasedSex);
    final deceasedAddress = _c(ud.deceasedAddress);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.of(context).viewInsets.bottom + 18),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const InvestigoPageTitle(title: 'UD Case Registration', subtitle: 'শুধু প্রাথমিক তথ্য দিন'),
              const SizedBox(height: 14),
              _field(udNo, 'UD Case No. / Year'),
              _field(gde, 'GDE No. & Date'),
              _picker(label: 'UD registration date', value: registration.text.split(' ').first, time: false, onChanged: (v) => setLocal(() => registration.text = '$v ${registration.text.contains(' ') ? registration.text.split(' ').last : ''}'.trim())),
              _picker(label: 'UD registration time', value: registration.text.contains(' ') ? registration.text.split(' ').last : '', time: true, onChanged: (v) => setLocal(() {
                final date = registration.text.contains(' ') ? registration.text.split(' ').first : registration.text;
                registration.text = '$date $v'.trim();
              })),
              _field(place, 'মৃতদেহ যেখানে পাওয়া গেছে', lines: 2),
              _field(informant, 'Informant-এর নাম'),
              _field(informantAddress, 'Informant-এর ঠিকানা', lines: 2),
              _field(deceased, 'মৃত ব্যক্তির নাম'),
              Row(children: [
                Expanded(child: _field(deceasedAge, 'বয়স')),
                const SizedBox(width: 8),
                Expanded(child: _field(deceasedSex, 'লিঙ্গ')),
              ]),
              _field(deceasedAddress, 'মৃত ব্যক্তির ঠিকানা', lines: 2),
              FilledButton(
                style: InvestigoUi.primaryButtonStyle(),
                onPressed: () {
                  final candidate = ud.copyWith({
                    'udNo': udNo.text.trim(),
                    'gdeNo': gde.text.trim(),
                    'dateTime': registration.text.trim(),
                    'placeFound': place.text.trim(),
                    'informantName': informant.text.trim(),
                    'informantAddress': informantAddress.text.trim(),
                    'deceasedName': deceased.text.trim(),
                    'deceasedAge': deceasedAge.text.trim(),
                    'deceasedSex': deceasedSex.text.trim(),
                    'deceasedAddress': deceasedAddress.text.trim(),
                    'policeStation': widget.profile.policeStation,
                    'district': widget.profile.district,
                  });
                  final result = _validator.registration(candidate);
                  if (!result.ok) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.errors.first)));
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: const Text('Save UD Registration'),
              ),
            ]),
          ),
        ),
      ),
    );

    if (saved == true) {
      final updated = ud.copyWith({
        'udNo': udNo.text.trim(),
        'gdeNo': gde.text.trim(),
        'dateTime': registration.text.trim(),
        'placeFound': place.text.trim(),
        'informantName': informant.text.trim(),
        'informantAddress': informantAddress.text.trim(),
        'deceasedName': deceased.text.trim(),
        'deceasedAge': deceasedAge.text.trim(),
        'deceasedSex': deceasedSex.text.trim(),
        'deceasedAddress': deceasedAddress.text.trim(),
        'policeStation': widget.profile.policeStation,
        'district': widget.profile.district,
      });
      await _saveUd(updated);
      if (isNew) {
        await _flowStore.save(UdLifecycleRecord.empty(updated.id));
        if (mounted) setState(() => _selectedId = updated.id);
        await _load();
      }
    }

    for (final controller in [udNo, gde, registration, place, informant, informantAddress, deceased, deceasedAge, deceasedSex, deceasedAddress]) {
      controller.dispose();
    }
  }

  Future<void> _completeInquest(UdCase ud, UdLifecycleRecord flow) async {
    // Simple mandatory stage fields.
    final spotDate = _c(flow.spotVisitDate);
    final spotTime = _c(flow.spotVisitTime);
    final date = _c(flow.inquestDate);
    final start = _c(flow.inquestStartTime);
    final end = _c(flow.inquestEndTime);
    final place = _c(flow.inquestPlace.isEmpty ? ud.placeFound : flow.inquestPlace);
    final identified = _c(ud.identifiedByName);
    final identifiedAddress = _c(ud.identifiedByAddress);
    final bodyPosition = _c(ud.bodyPosition);
    final dress = _c(ud.dress);
    final injuryOther = _c(ud.injuryOther);
    final witness1 = _c(ud.witness1NameAddress);
    final witness2 = _c(ud.witness2NameAddress);
    final observation = _c(flow.inquestObservation);

    // Full official INQUEST FORM fields. They stay collapsed by default so the
    // officer sees a simple workflow but can still fill every field printed in
    // the established form.
    final distance = _c(ud.distanceFromPs);
    final direction = _c(ud.directionFromPs);
    final longitude = _c(ud.longitude);
    final latitude = _c(ud.latitude);
    final foundDate = _c(ud.deadBodyFoundDate);
    final foundTime = _c(ud.deadBodyFoundTime);
    final identifierAge = _c(ud.identifiedByAge);
    final identifierSex = _c(ud.identifiedBySex);
    final identifierRelation = _c(ud.identifiedByRelation);
    final build = _c(ud.build);
    final height = _c(ud.height);
    final rigor = _c(ud.rigorMortis);
    final complexion = _c(ud.complexion);
    final deformities = _c(ud.deformities);
    final religion = _c(ud.religionRaceCommunity);
    final teeth = _c(ud.teeth);
    final eyes = _c(ud.eyes);
    final laceDerma = _c(ud.laceDerma);
    final mole = _c(ud.mole);
    final tattoo = _c(ud.tattoo);
    final otherFeatures = _c(ud.otherFeatures);

    final injuryHead = _c(ud.injuryHead);
    final injuryFace = _c(ud.injuryFace);
    final injuryNeck = _c(ud.injuryNeck);
    final injuryChest = _c(ud.injuryChest);
    final injuryStomach = _c(ud.injuryStomach);
    final injuryShoulder = _c(ud.injuryShoulder);
    final injuryRightHand = _c(ud.injuryRightHand);
    final injuryLeftHand = _c(ud.injuryLeftHand);
    final injuryRightLeg = _c(ud.injuryRightLeg);
    final injuryLeftLeg = _c(ud.injuryLeftLeg);
    final injuryPrivate = _c(ud.injuryPrivateParts);
    final injuryBack = _c(ud.injuryBack);

    final nostrils = _c(ud.nostrils);
    final earsEyes = _c(ud.earsEyes);
    final mouth = _c(ud.mouth);
    final penisVagina = _c(ud.penisVagina);
    final anus = _c(ud.anus);
    final weaponOpinion = _c(ud.weaponOpinion);
    final ligature = _c(ud.ligatureDescription);
    final foreignMaterial = _c(ud.foreignMaterial);
    final poDescription = _c(ud.poDescription);
    final articlesAtPo = _c(ud.articlesAtPo);
    final probableCause = _c(ud.probableCauseOfDeath);
    final remarks = _c(ud.remarks);
    final briefFacts = _c(ud.briefFacts);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            4,
            16,
            MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const InvestigoPageTitle(
                  title: 'সুরতহাল / Inquest',
                  subtitle: 'আগে দরকারি তথ্য দিন। সম্পূর্ণ official form-এর বাকি ঘর নিচে আছে।',
                ),
                const SizedBox(height: 14),
                _picker(
                  label: 'ঘটনাস্থলে যাওয়ার তারিখ',
                  value: spotDate.text,
                  time: false,
                  onChanged: (v) => setLocal(() => spotDate.text = v),
                ),
                _picker(
                  label: 'ঘটনাস্থলে যাওয়ার সময়',
                  value: spotTime.text,
                  time: true,
                  onChanged: (v) => setLocal(() => spotTime.text = v),
                ),
                _picker(
                  label: 'সুরতহালের তারিখ',
                  value: date.text,
                  time: false,
                  onChanged: (v) => setLocal(() => date.text = v),
                ),
                _picker(
                  label: 'সুরতহাল শুরুর সময়',
                  value: start.text,
                  time: true,
                  onChanged: (v) => setLocal(() => start.text = v),
                ),
                _picker(
                  label: 'সুরতহাল শেষের সময় (ঐচ্ছিক)',
                  value: end.text,
                  time: true,
                  onChanged: (v) => setLocal(() => end.text = v),
                ),
                _field(place, 'সুরতহালের স্থান', lines: 2),
                _field(identified, 'মৃতদেহ কে শনাক্ত করেছেন'),
                _field(identifiedAddress, 'শনাক্তকারীর ঠিকানা', lines: 2),
                _field(bodyPosition, 'মৃতদেহের অবস্থার বিবরণ', lines: 3),
                _field(dress, 'পরিধেয় পোশাক', lines: 2),
                _field(injuryOther, 'দৃশ্যমান আঘাত/অন্য চিহ্নের সারাংশ', lines: 3),
                _field(witness1, 'সুরতহাল সাক্ষী ১ — নাম ও ঠিকানা', lines: 2),
                _field(witness2, 'সুরতহাল সাক্ষী ২ — নাম ও ঠিকানা', lines: 2),
                _field(observation, 'Officer observation', lines: 3),
                const SizedBox(height: 6),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text(
                    'সম্পূর্ণ সুরতহাল ফর্মের আরও তথ্য',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: const Text('প্রয়োজনীয় ঘরগুলোই পূরণ করুন'),
                  children: [
                    _field(distance, 'থানা থেকে দূরত্ব'),
                    _field(direction, 'থানা থেকে দিক'),
                    _field(longitude, 'Longitude'),
                    _field(latitude, 'Latitude'),
                    _picker(label: 'মৃতদেহ পাওয়া/চিহ্নিত করার তারিখ', value: foundDate.text, time: false, onChanged: (v) => setLocal(() => foundDate.text = v)),
                    _picker(label: 'মৃতদেহ পাওয়া/চিহ্নিত করার সময়', value: foundTime.text, time: true, onChanged: (v) => setLocal(() => foundTime.text = v)),
                    _field(identifierAge, 'শনাক্তকারীর বয়স'),
                    _field(identifierSex, 'শনাক্তকারীর লিঙ্গ'),
                    _field(identifierRelation, 'মৃত ব্যক্তির সঙ্গে সম্পর্ক'),
                    _field(build, 'Dead Body Build'),
                    _field(height, 'Height'),
                    _field(rigor, 'Rigor Mortis'),
                    _field(complexion, 'Complexion'),
                    _field(deformities, 'Deformities, if any', lines: 2),
                    _field(religion, 'Religion / Race / Community'),
                    _field(teeth, 'Identification mark — Teeth'),
                    _field(eyes, 'Eyes'),
                    _field(laceDerma, 'Lace derma'),
                    _field(mole, 'Mole'),
                    _field(tattoo, 'Tattoo'),
                    _field(otherFeatures, 'Other identifying features', lines: 2),
                    const Divider(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('শরীরের অংশ অনুযায়ী আঘাত', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                    _field(injuryHead, 'Head', lines: 2),
                    _field(injuryFace, 'Face', lines: 2),
                    _field(injuryNeck, 'Neck', lines: 2),
                    _field(injuryChest, 'Chest', lines: 2),
                    _field(injuryStomach, 'Stomach / Abdomen', lines: 2),
                    _field(injuryShoulder, 'Shoulder', lines: 2),
                    _field(injuryRightHand, 'Right Hand', lines: 2),
                    _field(injuryLeftHand, 'Left Hand', lines: 2),
                    _field(injuryRightLeg, 'Right Leg', lines: 2),
                    _field(injuryLeftLeg, 'Left Leg', lines: 2),
                    _field(injuryPrivate, 'Private parts', lines: 2),
                    _field(injuryBack, 'Back', lines: 2),
                    const Divider(height: 24),
                    _field(nostrils, 'Nostrils'),
                    _field(earsEyes, 'Ears / Eyes'),
                    _field(mouth, 'Mouth'),
                    _field(penisVagina, 'Penis / Vagina'),
                    _field(anus, 'Anus'),
                    _field(weaponOpinion, 'Opinion on nature of weapon / manner of injury', lines: 3),
                    _field(ligature, 'Ligature mark / rope / knot description', lines: 3),
                    _field(foreignMaterial, 'Foreign material found on body', lines: 3),
                    _field(poDescription, 'Description of place of occurrence', lines: 3),
                    _field(articlesAtPo, 'Articles at P.O. including weapon/ornaments', lines: 3),
                    _field(probableCause, 'Probable cause of death at inquest stage, if officer records any', lines: 2),
                    _field(remarks, 'Remarks', lines: 3),
                    _field(briefFacts, 'Brief facts — separate sheet text', lines: 5),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton(
                  style: InvestigoUi.primaryButtonStyle(),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Validate & Final Inquest'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (ok == true) {
      final updatedUd = ud.copyWith({
        'distanceFromPs': distance.text.trim(),
        'directionFromPs': direction.text.trim(),
        'longitude': longitude.text.trim(),
        'latitude': latitude.text.trim(),
        'deadBodyFoundDate': foundDate.text.trim(),
        'deadBodyFoundTime': foundTime.text.trim(),
        'identifiedByName': identified.text.trim(),
        'identifiedByAge': identifierAge.text.trim(),
        'identifiedBySex': identifierSex.text.trim(),
        'identifiedByRelation': identifierRelation.text.trim(),
        'identifiedByAddress': identifiedAddress.text.trim(),
        'bodyPosition': bodyPosition.text.trim(),
        'build': build.text.trim(),
        'height': height.text.trim(),
        'rigorMortis': rigor.text.trim(),
        'complexion': complexion.text.trim(),
        'deformities': deformities.text.trim(),
        'religionRaceCommunity': religion.text.trim(),
        'teeth': teeth.text.trim(),
        'eyes': eyes.text.trim(),
        'laceDerma': laceDerma.text.trim(),
        'mole': mole.text.trim(),
        'tattoo': tattoo.text.trim(),
        'dress': dress.text.trim(),
        'otherFeatures': otherFeatures.text.trim(),
        'injuryHead': injuryHead.text.trim(),
        'injuryFace': injuryFace.text.trim(),
        'injuryNeck': injuryNeck.text.trim(),
        'injuryChest': injuryChest.text.trim(),
        'injuryStomach': injuryStomach.text.trim(),
        'injuryShoulder': injuryShoulder.text.trim(),
        'injuryRightHand': injuryRightHand.text.trim(),
        'injuryLeftHand': injuryLeftHand.text.trim(),
        'injuryRightLeg': injuryRightLeg.text.trim(),
        'injuryLeftLeg': injuryLeftLeg.text.trim(),
        'injuryPrivateParts': injuryPrivate.text.trim(),
        'injuryBack': injuryBack.text.trim(),
        'injuryOther': injuryOther.text.trim(),
        'nostrils': nostrils.text.trim(),
        'earsEyes': earsEyes.text.trim(),
        'mouth': mouth.text.trim(),
        'penisVagina': penisVagina.text.trim(),
        'anus': anus.text.trim(),
        'weaponOpinion': weaponOpinion.text.trim(),
        'ligatureDescription': ligature.text.trim(),
        'foreignMaterial': foreignMaterial.text.trim(),
        'poDescription': poDescription.text.trim(),
        'articlesAtPo': articlesAtPo.text.trim(),
        'probableCauseOfDeath': probableCause.text.trim(),
        'remarks': remarks.text.trim(),
        'witness1NameAddress': witness1.text.trim(),
        'witness2NameAddress': witness2.text.trim(),
        'briefFacts': briefFacts.text.trim(),
      });
      final updatedFlow = flow.copyWith(
        spotVisitDate: spotDate.text.trim(),
        spotVisitTime: spotTime.text.trim(),
        inquestDate: date.text.trim(),
        inquestStartTime: start.text.trim(),
        inquestEndTime: end.text.trim(),
        inquestPlace: place.text.trim(),
        inquestObservation: observation.text.trim(),
      );
      final result = _validator.inquest(updatedUd, updatedFlow);
      if (!result.ok) {
        await _showErrors(result);
      } else {
        await _saveUd(updatedUd);
        await _saveFlow(updatedFlow.copyWith(inquestCompleted: true));
      }
    }

    for (final c in [
      spotDate, spotTime, date, start, end, place, identified, identifiedAddress,
      bodyPosition, dress, injuryOther, witness1, witness2, observation,
      distance, direction, longitude, latitude, foundDate, foundTime,
      identifierAge, identifierSex, identifierRelation, build, height, rigor,
      complexion, deformities, religion, teeth, eyes, laceDerma, mole, tattoo,
      otherFeatures, injuryHead, injuryFace, injuryNeck, injuryChest,
      injuryStomach, injuryShoulder, injuryRightHand, injuryLeftHand,
      injuryRightLeg, injuryLeftLeg, injuryPrivate, injuryBack, nostrils,
      earsEyes, mouth, penisVagina, anus, weaponOpinion, ligature,
      foreignMaterial, poDescription, articlesAtPo, probableCause, remarks,
      briefFacts,
    ]) {
      c.dispose();
    }
  }

  Future<void> _prepareChallan(UdCase ud, UdLifecycleRecord flow) async {
    final pmDate = _c(flow.pmPlannedDate);
    final challanDate = _c(flow.challanDate);
    final challanTime = _c(flow.challanTime);
    final dispatchDate = _c(flow.bodyDispatchDate);
    final dispatchTime = _c(flow.bodyDispatchTime);
    final hospital = _c(flow.pmHospital.isEmpty ? widget.profile.defaultHospital : flow.pmHospital);
    final means = _c(flow.meansOfDispatch);
    final escort = _c(flow.escortDetails);
    final docs = _c(flow.documentsSent.isEmpty ? 'Inquest/Surathal Report; Dead Body Challan; connected papers' : flow.documentsSent);
    final articles = _c(flow.articlesSent);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(builder: (context, setLocal) => Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.of(context).viewInsets.bottom + 18),
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const InvestigoPageTitle(title: 'Dead Body Challan / PM Forwarding', subtitle: 'সাধারণত PM-এর দিন বা আগের দিন'),
          const SizedBox(height: 14),
          _picker(label: 'নির্ধারিত PM date', value: pmDate.text, time: false, onChanged: (v) => setLocal(() => pmDate.text = v)),
          _picker(label: 'Challan date', value: challanDate.text, time: false, onChanged: (v) => setLocal(() => challanDate.text = v)),
          _picker(label: 'Challan time', value: challanTime.text, time: true, onChanged: (v) => setLocal(() => challanTime.text = v)),
          _picker(label: 'মৃতদেহ dispatch date', value: dispatchDate.text, time: false, onChanged: (v) => setLocal(() => dispatchDate.text = v)),
          _picker(label: 'মৃতদেহ dispatch time', value: dispatchTime.text, time: true, onChanged: (v) => setLocal(() => dispatchTime.text = v)),
          _field(hospital, 'PM Hospital / Morgue', lines: 2),
          _field(means, 'Means of dispatch — কীভাবে পাঠানো হচ্ছে'),
          _field(escort, 'Escort / Messenger details', lines: 2),
          _field(docs, 'সঙ্গে পাঠানো documents', lines: 3),
          _field(articles, 'সঙ্গে পাঠানো articles, if any', lines: 3),
          FilledButton(style: InvestigoUi.primaryButtonStyle(), onPressed: () => Navigator.pop(context, true), child: const Text('Validate & Final Challan')),
        ])),
      )),
    );

    if (ok == true) {
      final candidate = flow.copyWith(
        pmPlannedDate: pmDate.text.trim(),
        challanDate: challanDate.text.trim(),
        challanTime: challanTime.text.trim(),
        bodyDispatchDate: dispatchDate.text.trim(),
        bodyDispatchTime: dispatchTime.text.trim(),
        pmHospital: hospital.text.trim(),
        meansOfDispatch: means.text.trim(),
        escortDetails: escort.text.trim(),
        documentsSent: docs.text.trim(),
        articlesSent: articles.text.trim(),
      );
      final result = _validator.challan(ud, candidate);
      if (!result.ok) {
        await _showErrors(result);
      } else if (await _confirmWarnings(result)) {
        await _saveFlow(candidate.copyWith(challanFinalized: true));
      }
    }
    for (final c in [pmDate, challanDate, challanTime, dispatchDate, dispatchTime, hospital, means, escort, docs, articles]) { c.dispose(); }
  }

  Future<void> _markPmCompleted(UdLifecycleRecord flow) async {
    final date = _c(flow.pmDate.isEmpty ? flow.pmPlannedDate : flow.pmDate);
    final time = _c(flow.pmTime);
    final number = _c(flow.pmNumber);
    final doctor = _c(flow.doctorName);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(builder: (context, setLocal) => Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.of(context).viewInsets.bottom + 18),
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const InvestigoPageTitle(title: 'Post Mortem সম্পন্ন', subtitle: 'শুধু PM completion details'),
          const SizedBox(height: 14),
          _picker(label: 'PM date', value: date.text, time: false, onChanged: (v) => setLocal(() => date.text = v)),
          _picker(label: 'PM time', value: time.text, time: true, onChanged: (v) => setLocal(() => time.text = v)),
          _field(number, 'PM No. / Reference'),
          _field(doctor, 'Doctor name, if known'),
          FilledButton(style: InvestigoUi.primaryButtonStyle(), onPressed: () => Navigator.pop(context, true), child: const Text('Mark PM Completed')),
        ])),
      )),
    );
    if (ok == true) {
      final candidate = flow.copyWith(pmDate: date.text.trim(), pmTime: time.text.trim(), pmNumber: number.text.trim(), doctorName: doctor.text.trim());
      final result = _validator.pmCompleted(candidate);
      if (!result.ok) await _showErrors(result); else await _saveFlow(candidate.copyWith(pmCompleted: true));
    }
    for (final c in [date, time, number, doctor]) { c.dispose(); }
  }

  Future<void> _receivePmReport(UdLifecycleRecord flow) async {
    final reportNo = _c(flow.pmReportNo);
    final reportDate = _c(flow.pmReportDate.isEmpty ? flow.pmDate : flow.pmReportDate);
    final receivedDate = _c(flow.pmReportReceivedDate);
    final cause = _c(flow.causeOfDeath);
    final injuries = _c(flow.injuryFindings);
    final opinion = _c(flow.medicalOpinion);
    final other = _c(flow.otherMedicalOpinion);
    bool viscera = flow.visceraPreserved;
    bool pending = flow.otherReportPending;
    final pendingDetails = _c(flow.pendingReportDetails);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(builder: (context, setLocal) => Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.of(context).viewInsets.bottom + 18),
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const InvestigoPageTitle(title: 'PM Report পাওয়া গেছে', subtitle: 'Report দেখে হুবহু প্রয়োজনীয় opinion লিখুন'),
          const SizedBox(height: 14),
          _field(reportNo, 'PM Report No.'),
          _picker(label: 'PM Report date', value: reportDate.text, time: false, onChanged: (v) => setLocal(() => reportDate.text = v)),
          _picker(label: 'Report received date', value: receivedDate.text, time: false, onChanged: (v) => setLocal(() => receivedDate.text = v)),
          _field(cause, 'Cause of death as per PM Report', lines: 3),
          _field(injuries, 'Injury findings as per PM Report', lines: 4),
          _field(opinion, 'Medical opinion', lines: 3),
          SwitchListTile(contentPadding: EdgeInsets.zero, value: viscera, onChanged: (v) => setLocal(() => viscera = v), title: const Text('Viscera preserved?')),
          SwitchListTile(contentPadding: EdgeInsets.zero, value: pending, onChanged: (v) => setLocal(() => pending = v), title: const Text('Viscera/FSL/Chemical/other report pending?')),
          if (pending) _field(pendingDetails, 'Pending report details', lines: 2),
          _field(other, 'Other medical opinion, if any', lines: 3),
          FilledButton(style: InvestigoUi.primaryButtonStyle(), onPressed: () => Navigator.pop(context, true), child: const Text('Save PM Report Details')),
        ])),
      )),
    );
    if (ok == true) {
      final candidate = flow.copyWith(
        pmReportNo: reportNo.text.trim(), pmReportDate: reportDate.text.trim(), pmReportReceivedDate: receivedDate.text.trim(),
        causeOfDeath: cause.text.trim(), injuryFindings: injuries.text.trim(), medicalOpinion: opinion.text.trim(),
        visceraPreserved: viscera, otherReportPending: pending, pendingReportDetails: pendingDetails.text.trim(), otherMedicalOpinion: other.text.trim(),
      );
      final result = _validator.pmReport(candidate);
      if (!result.ok) await _showErrors(result); else await _saveFlow(candidate.copyWith(pmReportReceived: true));
    }
    for (final c in [reportNo, reportDate, receivedDate, cause, injuries, opinion, pendingDetails, other]) { c.dispose(); }
  }

  Future<void> _prepareFinal(UdLifecycleRecord flow) async {
    var assessment = flow.foulPlayAssessment;
    bool pending = flow.otherReportPending;
    final pendingDetails = _c(flow.pendingReportDetails);
    final summary = _c(flow.finalInvestigationSummary);
    final dispatchDate = _c(flow.finalDispatchDate);
    final dispatchTime = _c(flow.finalDispatchTime);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(builder: (context, setLocal) => Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.of(context).viewInsets.bottom + 18),
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const InvestigoPageTitle(title: 'UD Final Form', subtitle: 'PM Report পাওয়ার পর officer-এর verified finding'),
          const SizedBox(height: 14),
          const Text('তদন্তে foul play সম্পর্কে আপনার finding কী?', style: TextStyle(fontWeight: FontWeight.w900)),
          ...[
            (UdFoulPlayAssessment.detected, 'Foul play / criminality detected'),
            (UdFoulPlayAssessment.notDetected, 'No foul play detected'),
            (UdFoulPlayAssessment.inconclusive, 'Inconclusive'),
          ].map((item) => RadioListTile<UdFoulPlayAssessment>(value: item.$1, groupValue: assessment, onChanged: (v) => setLocal(() => assessment = v ?? assessment), title: Text(item.$2))),
          SwitchListTile(contentPadding: EdgeInsets.zero, value: pending, onChanged: (v) => setLocal(() => pending = v), title: const Text('কোনো অন্য report এখনো pending আছে?')),
          if (pending) _field(pendingDetails, 'Pending report details', lines: 2),
          _field(summary, 'Officer-verified final investigation/enquiry summary', lines: 6),
          _picker(label: 'Final Report dispatch date', value: dispatchDate.text, time: false, onChanged: (v) => setLocal(() => dispatchDate.text = v)),
          _picker(label: 'Final Report dispatch time', value: dispatchTime.text, time: true, onChanged: (v) => setLocal(() => dispatchTime.text = v)),
          FilledButton(style: InvestigoUi.primaryButtonStyle(), onPressed: () => Navigator.pop(context, true), child: const Text('Validate Final Form')),
        ])),
      )),
    );
    if (ok == true) {
      final candidate = flow.copyWith(
        foulPlayAssessment: assessment,
        otherReportPending: pending,
        pendingReportDetails: pendingDetails.text.trim(),
        finalInvestigationSummary: summary.text.trim(),
        finalDispatchDate: dispatchDate.text.trim(),
        finalDispatchTime: dispatchTime.text.trim(),
      );
      final result = _validator.finalReport(candidate);
      if (!result.ok) await _showErrors(result); else await _saveFlow(candidate);
    }
    for (final c in [pendingDetails, summary, dispatchDate, dispatchTime]) { c.dispose(); }
  }

  Future<void> _finalize(UdLifecycleRecord flow) async {
    final result = _validator.finalReport(flow);
    if (!result.ok) { await _showErrors(result); return; }
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('UD Finalize করবেন?'),
      content: const Text('Final করার আগে Preview দেখে PM Report, cause of death, foul-play finding এবং dispatch date/time মিলিয়ে নিন।'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Finalize'))],
    ));
    if (ok == true) await _saveFlow(flow.copyWith(finalized: true));
  }

  Future<void> _previewInquest(UdCase ud, UdLifecycleRecord flow) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(
      title: 'Surathal / Inquest Preview', filename: 'UD_Inquest_${ud.udNo.replaceAll('/', '_')}.pdf', docFilename: 'UD_Inquest_${ud.udNo.replaceAll('/', '_')}.doc',
      buildPdf: () => _documents.buildInquestPdf(officer: widget.profile, ud: ud, flow: flow),
      buildDoc: () async => _documents.buildInquestDoc(officer: widget.profile, ud: ud, flow: flow),
    )));
  }

  Future<void> _previewChallan(UdCase ud, UdLifecycleRecord flow) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(
      title: 'Dead Body Challan Preview', filename: 'UD_Dead_Body_Challan_${ud.udNo.replaceAll('/', '_')}.pdf', docFilename: 'UD_Dead_Body_Challan_${ud.udNo.replaceAll('/', '_')}.doc',
      buildPdf: () => _documents.buildDeadBodyChallanPdf(officer: widget.profile, ud: ud, flow: flow),
      buildDoc: () async => _documents.buildDeadBodyChallanDoc(officer: widget.profile, ud: ud, flow: flow),
    )));
  }

  Future<void> _previewFinal(UdCase ud, UdLifecycleRecord flow) async {
    final result = _validator.finalReport(flow);
    if (!result.ok) { await _showErrors(result); return; }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(
      title: 'UD Final Report Preview', filename: 'UD_Final_Report_${ud.udNo.replaceAll('/', '_')}.pdf', docFilename: 'UD_Final_Report_${ud.udNo.replaceAll('/', '_')}.doc',
      buildPdf: () => _documents.buildFinalReportPdf(officer: widget.profile, ud: ud, flow: flow),
      buildDoc: () async => _documents.buildFinalReportDoc(officer: widget.profile, ud: ud, flow: flow),
    )));
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedUd;
    return Scaffold(
      backgroundColor: InvestigoUi.background,
      appBar: AppBar(
        backgroundColor: InvestigoUi.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('UD Case'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newUd,
        backgroundColor: InvestigoUi.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('নতুন UD Case'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            const InvestigoPageTitle(
              title: 'UD Case Workflow',
              subtitle: 'এক ধাপ শেষ হলে পরের ধাপ খুলবে — একসঙ্গে সব form নয়',
            ),
            const SizedBox(height: 14),
            if (_uds.isEmpty)
              Container(
                decoration: InvestigoUi.cardDecoration(),
                padding: const EdgeInsets.all(22),
                child: const Column(children: [
                  Icon(Icons.assignment_outlined, size: 44, color: InvestigoUi.muted),
                  SizedBox(height: 10),
                  Text('এখনও কোনো UD Case নেই। নিচের “নতুন UD Case” বাটনে চাপুন।', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
                ]),
              )
            else ...[
              DropdownButtonFormField<String>(
                value: _selectedId,
                decoration: const InputDecoration(labelText: 'UD Case নির্বাচন করুন', border: OutlineInputBorder()),
                items: _uds.map((ud) => DropdownMenuItem(value: ud.id, child: Text('${ud.displayTitle} • ${ud.deceasedName}'))).toList(),
                onChanged: (v) => setState(() => _selectedId = v),
              ),
              const SizedBox(height: 14),
              if (selected != null) _workflow(selected, _flowFor(selected)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _workflow(UdCase ud, UdLifecycleRecord flow) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        decoration: InvestigoUi.cardDecoration(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(ud.displayTitle, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
            _stageChip(flow.stageLabelBn),
          ]),
          const SizedBox(height: 8),
          Text('মৃত: ${ud.deceasedName}\nস্থান: ${ud.placeFound}\nরেজিস্ট্রেশন: ${ud.dateTime}', style: const TextStyle(color: InvestigoUi.muted, height: 1.4)),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: () => _editRegistration(ud), icon: const Icon(Icons.edit_outlined), label: const Text('Registration তথ্য ঠিক করুন')),
        ]),
      ),
      const SizedBox(height: 14),
      _stageCard(
        no: 1,
        title: 'সুরতহাল / Inquest',
        subtitle: flow.inquestCompleted ? '${flow.inquestDate} ${flow.inquestStartTime} • Completed' : 'তারিখ, সময়, body condition, witnesses',
        done: flow.inquestCompleted,
        enabled: true,
        actionLabel: flow.inquestCompleted ? 'Edit Inquest' : 'Fill Inquest',
        onAction: () => _completeInquest(ud, flow),
        onPreview: flow.inquestCompleted ? () => _previewInquest(ud, flow) : null,
      ),
      _stageCard(
        no: 2,
        title: 'Dead Body Challan / PM Forwarding',
        subtitle: flow.challanFinalized ? 'PM: ${flow.pmPlannedDate} • Dispatch: ${flow.bodyDispatchDate} ${flow.bodyDispatchTime}' : 'PM-এর দিন বা আগের দিনের challan/dispatch',
        done: flow.challanFinalized,
        enabled: flow.inquestCompleted,
        actionLabel: flow.challanFinalized ? 'Edit Challan' : 'Prepare Challan',
        onAction: () => _prepareChallan(ud, flow),
        onPreview: flow.challanFinalized ? () => _previewChallan(ud, flow) : null,
      ),
      _stageCard(
        no: 3,
        title: 'Post Mortem Completed',
        subtitle: flow.pmCompleted ? 'PM No. ${flow.pmNumber} • ${flow.pmDate} ${flow.pmTime}' : 'PM হয়ে গেলে completion details দিন',
        done: flow.pmCompleted,
        enabled: flow.challanFinalized,
        actionLabel: flow.pmCompleted ? 'Edit PM Details' : 'PM সম্পন্ন হয়েছে',
        onAction: () => _markPmCompleted(flow),
      ),
      _stageCard(
        no: 4,
        title: 'PM Report Received',
        subtitle: flow.pmReportReceived ? 'Report ${flow.pmReportNo} • Received ${flow.pmReportReceivedDate}' : 'PM Report হাতে আসার পর এই ধাপ',
        done: flow.pmReportReceived,
        enabled: flow.pmCompleted,
        actionLabel: flow.pmReportReceived ? 'Edit PM Report' : 'PM Report পাওয়া গেছে',
        onAction: () => _receivePmReport(flow),
      ),
      _stageCard(
        no: 5,
        title: 'UD Final Form',
        subtitle: flow.finalized ? 'Finalized • ${flow.finalDispatchDate} ${flow.finalDispatchTime}' : (flow.otherReportPending ? 'অন্য report pending — Final blocked' : 'Officer finding + final summary + dispatch'),
        done: flow.finalized,
        enabled: flow.pmReportReceived,
        actionLabel: flow.finalized ? 'Finalized' : 'Prepare Final Form',
        onAction: flow.finalized ? null : () => _prepareFinal(flow),
        onPreview: flow.pmReportReceived ? () => _previewFinal(ud, flow) : null,
        onFinal: flow.stage == UdWorkflowStage.readyForFinalReport ? () => _finalize(flow) : null,
      ),
    ]);
  }

  Widget _stageChip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(color: InvestigoUi.primary.withOpacity(.08), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: const TextStyle(color: InvestigoUi.primaryDark, fontWeight: FontWeight.w900, fontSize: 10.5)),
      );

  Widget _stageCard({
    required int no,
    required String title,
    required String subtitle,
    required bool done,
    required bool enabled,
    required String actionLabel,
    VoidCallback? onAction,
    VoidCallback? onPreview,
    VoidCallback? onFinal,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Container(
        decoration: InvestigoUi.cardDecoration(color: enabled ? Colors.white : const Color(0xFFF0F2F6)),
        padding: const EdgeInsets.all(15),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: done ? InvestigoUi.success.withOpacity(.1) : InvestigoUi.primary.withOpacity(.08), borderRadius: BorderRadius.circular(13)),
            child: Center(child: done ? const Icon(Icons.check_rounded, color: InvestigoUi.success) : Text('$no', style: const TextStyle(color: InvestigoUi.primary, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: enabled ? InvestigoUi.text : InvestigoUi.muted)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: InvestigoUi.muted, fontSize: 12.2, height: 1.35)),
            if (enabled) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (onAction != null) FilledButton.tonal(onPressed: onAction, child: Text(actionLabel)),
                if (onPreview != null) OutlinedButton.icon(onPressed: onPreview, icon: const Icon(Icons.preview_outlined, size: 18), label: const Text('Preview')),
                if (onFinal != null) FilledButton.icon(onPressed: onFinal, icon: const Icon(Icons.lock_outline, size: 18), label: const Text('Final Save')),
              ]),
            ],
          ])),
        ]),
      ),
    );
  }
}
