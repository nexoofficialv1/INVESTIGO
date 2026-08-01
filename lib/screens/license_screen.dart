import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_theme.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final _upiController = TextEditingController();
  final _txnController = TextEditingController();
  final _activationController = TextEditingController();
  final _feeController = TextEditingController();
  String _plan = 'Free / Offline Trial';
  String _status = 'Not activated';
  String _fee = 'To be configured';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _plan = prefs.getString('license_plan_v1') ?? 'Free / Offline Trial';
      _status = prefs.getString('license_status_v1') ?? 'Not activated';
      _fee = prefs.getString('license_fee_v1') ?? 'To be configured';
      _feeController.text = _fee;
      _upiController.text = prefs.getString('license_upi_v1') ?? '';
      _txnController.text = prefs.getString('license_txn_v1') ?? '';
      _activationController.text = prefs.getString('license_code_v1') ?? '';
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('license_plan_v1', _plan);
    await prefs.setString('license_status_v1', _status);
    await prefs.setString('license_fee_v1', _feeController.text.trim().isEmpty ? _fee : _feeController.text.trim());
    await prefs.setString('license_upi_v1', _upiController.text.trim());
    await prefs.setString('license_txn_v1', _txnController.text.trim());
    await prefs.setString('license_code_v1', _activationController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('License/payment settings saved')));
  }

  Future<void> _activateOffline() async {
    final code = _activationController.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid activation code')));
      return;
    }
    setState(() => _status = 'Activated locally');
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: const Text('License & Fees')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Current License', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 8),
                Text('Plan: $_plan'),
                Text('Status: $_status'),
                Text('Fee: $_fee'),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Plan / Fee Setup', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _plan,
                  decoration: const InputDecoration(labelText: 'Plan'),
                  items: const [
                    DropdownMenuItem(value: 'Free / Offline Trial', child: Text('Free / Offline Trial')),
                    DropdownMenuItem(value: 'Monthly License', child: Text('Monthly License')),
                    DropdownMenuItem(value: 'Yearly License', child: Text('Yearly License')),
                    DropdownMenuItem(value: 'Lifetime / Manual Activation', child: Text('Lifetime / Manual Activation')),
                  ],
                  onChanged: (v) => setState(() => _plan = v ?? _plan),
                ),
                const SizedBox(height: 8),
                TextField(controller: _feeController, decoration: const InputDecoration(labelText: 'Fee Amount / Note')),
                const SizedBox(height: 8),
                TextField(controller: _upiController, decoration: const InputDecoration(labelText: 'UPI ID / Payment details')),
                const SizedBox(height: 8),
                TextField(controller: _txnController, decoration: const InputDecoration(labelText: 'Transaction ID / Receipt No.')),
                const SizedBox(height: 8),
                TextField(controller: _activationController, decoration: const InputDecoration(labelText: 'Activation Code')),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save'))),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(onPressed: _activateOffline, icon: const Icon(Icons.verified), label: const Text('Activate'))),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text('Note: এখন local/manual license record থাকবে। Backend server যুক্ত হলে license verification, expiry, renewal, payment receipt upload, and server-side activation add করা যাবে।'),
            ),
          ),
        ],
      ),
    );
  }
}
