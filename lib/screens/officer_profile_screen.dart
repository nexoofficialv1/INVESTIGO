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
  late final TextEditingController name;
  late final TextEditingController rank;
  late final TextEditingController beltNo;
  late final TextEditingController ps;
  late final TextEditingController district;
  late final TextEditingController court;
  late final TextEditingController mobile;
  late final TextEditingController email;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    name = TextEditingController(text: p.name);
    rank = TextEditingController(text: p.rank);
    beltNo = TextEditingController(text: p.beltNo);
    ps = TextEditingController(text: p.policeStation);
    district = TextEditingController(text: p.district);
    court = TextEditingController(text: p.courtName);
    mobile = TextEditingController(text: p.mobile);
    email = TextEditingController(text: p.email);
  }

  @override
  void dispose() {
    name.dispose();
    rank.dispose();
    beltNo.dispose();
    ps.dispose();
    district.dispose();
    court.dispose();
    mobile.dispose();
    email.dispose();
    super.dispose();
  }

  void _save() {
    if (name.text.trim().isEmpty || rank.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Officer name and rank required')));
      return;
    }
    widget.onSaved(OfficerProfile(
      name: name.text.trim(),
      rank: rank.text.trim(),
      beltNo: beltNo.text.trim(),
      policeStation: ps.text.trim(),
      district: district.text.trim(),
      courtName: court.text.trim(),
      mobile: mobile.text.trim(),
      email: email.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Officer Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('প্রথমে officer profile সেট করুন। এই profile থেকে CD, statement, form auto-fill হবে।', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          FormHelpers.textField(controller: name, label: 'Officer Name'),
          FormHelpers.textField(controller: rank, label: 'Rank'),
          FormHelpers.textField(controller: beltNo, label: 'Belt / ID No.'),
          FormHelpers.textField(controller: ps, label: 'Police Station'),
          FormHelpers.textField(controller: district, label: 'District'),
          FormHelpers.textField(controller: court, label: 'Default Court'),
          FormHelpers.textField(controller: mobile, label: 'Mobile No.'),
          FormHelpers.textField(controller: email, label: 'Email'),
          const SizedBox(height: 10),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save Profile')),
        ],
      ),
    );
  }
}
