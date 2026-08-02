import 'package:flutter/material.dart';

import '../models/officer_profile.dart';
import '../widgets/form_helpers.dart';

class OfficerProfileScreen extends StatefulWidget {
  final OfficerProfile profile;
  final ValueChanged<OfficerProfile> onSaved;

  const OfficerProfileScreen({super.key, required this.profile, required this.onSaved});

  @override
  State<OfficerProfileScreen> createState() => _OfficerProfileScreenState();
}

class _OfficerProfileScreenState extends State<OfficerProfileScreen> {
  final Map<String, TextEditingController> _c = {};

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    final values = <String, String>{
      'name': p.name,
      'rank': p.rank,
      'beltNo': p.beltNo,
      'policeStation': p.policeStation,
      'district': p.district,
      'courtName': p.courtName,
      'mobile': p.mobile,
      'cugMobile': p.cugMobile,
      'whatsApp': p.whatsApp,
      'email': p.email,
      'psAddress': p.psAddress,
      'pinCode': p.pinCode,
      'defaultHospital': p.defaultHospital,
      'defaultMorgue': p.defaultMorgue,
      'defaultFslOffice': p.defaultFslOffice,
      'defaultSdpoOffice': p.defaultSdpoOffice,
    };
    for (final entry in values.entries) {
      _c[entry.key] = TextEditingController(text: entry.value);
    }
  }

  @override
  void dispose() {
    for (final controller in _c.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _v(String key) => _c[key]!.text.trim();

  void _save() {
    if (_v('name').isEmpty ||
        _v('rank').isEmpty ||
        _v('policeStation').isEmpty ||
        _v('district').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Officer name, rank, Police Station and District are required.')),
      );
      return;
    }
    widget.onSaved(OfficerProfile(
      name: _v('name'),
      rank: _v('rank'),
      beltNo: _v('beltNo'),
      policeStation: _v('policeStation'),
      district: _v('district'),
      courtName: _v('courtName'),
      mobile: _v('mobile'),
      cugMobile: _v('cugMobile'),
      whatsApp: _v('whatsApp'),
      email: _v('email'),
      psAddress: _v('psAddress'),
      pinCode: _v('pinCode'),
      defaultHospital: _v('defaultHospital'),
      defaultMorgue: _v('defaultMorgue'),
      defaultFslOffice: _v('defaultFslOffice'),
      defaultSdpoOffice: _v('defaultSdpoOffice'),
    ));
  }

  Widget _field(String key, String label, {int lines = 1}) =>
      FormHelpers.textField(controller: _c[key]!, label: label, maxLines: lines);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Officer & Station Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'এই Profile-এর Police Station, District, Court, Hospital, Morgue এবং FSL office সব সরকারি form-এ ব্যবহার হবে। কোনো নির্দিষ্ট থানার নাম hard-coded থাকবে না।',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _field('name', 'Officer Name *'),
          _field('rank', 'Rank *'),
          _field('beltNo', 'Belt / Force / ID No.'),
          _field('policeStation', 'Police Station *'),
          _field('district', 'District *'),
          _field('psAddress', 'Police Station Address', lines: 2),
          _field('pinCode', 'PIN Code'),
          _field('courtName', 'Default Court'),
          _field('defaultSdpoOffice', 'Default SDPO / Supervisory Office'),
          _field('defaultHospital', 'Default Hospital'),
          _field('defaultMorgue', 'Default Morgue / PM Centre'),
          _field('defaultFslOffice', 'Default FSL / RFSL Office', lines: 3),
          _field('mobile', 'Officer Mobile No.'),
          _field('cugMobile', 'PS CUG Mobile No.'),
          _field('whatsApp', 'WhatsApp No.'),
          _field('email', 'Police Station Email'),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save Profile')),
        ],
      ),
    );
  }
}
