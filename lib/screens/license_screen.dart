import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/offline_license_service.dart';
import '../widgets/investigo_ui.dart';

class LicenseScreen extends StatefulWidget {
  final bool allowBack;
  final Future<void> Function()? onLicenseChanged;

  const LicenseScreen({
    super.key,
    this.allowBack = true,
    this.onLicenseChanged,
  });

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final OfflineLicenseService _service = OfflineLicenseService();
  final TextEditingController _activationController =
      TextEditingController();

  OfflineLicenseSnapshot? _snapshot;
  bool _loading = true;
  bool _activating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _activationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final snapshot = await _service.evaluate();
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _loading = false;
    });
  }

  Future<void> _activate() async {
    if (_activating) return;
    setState(() => _activating = true);
    final result = await _service.activate(_activationController.text);
    if (!mounted) return;
    setState(() => _activating = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
    if (result.success) {
      _activationController.clear();
      await _load();
      await widget.onLicenseChanged?.call();
    }
  }

  Future<void> _copyDeviceCode(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Device code copied')),
    );
  }

  String _statusTitle(OfflineLicenseSnapshot value) {
    switch (value.state) {
      case OfflineLicenseState.trial:
        return '14-Day Trial';
      case OfflineLicenseState.licensed:
        return 'Yearly License Active';
      case OfflineLicenseState.expired:
        return 'Activation Required';
      case OfflineLicenseState.clockError:
        return 'Date / Time Check Required';
    }
  }

  IconData _statusIcon(OfflineLicenseSnapshot value) {
    switch (value.state) {
      case OfflineLicenseState.trial:
        return Icons.hourglass_top_rounded;
      case OfflineLicenseState.licensed:
        return Icons.verified_user_rounded;
      case OfflineLicenseState.expired:
        return Icons.lock_clock_rounded;
      case OfflineLicenseState.clockError:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InvestigoUi.background,
      appBar: AppBar(
        automaticallyImplyLeading: widget.allowBack,
        backgroundColor: InvestigoUi.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'INVESTIGO License',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(_snapshot!),
    );
  }

  Widget _buildContent(OfflineLicenseSnapshot value) {
    final active = value.canUseApp;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: active
                  ? const [InvestigoUi.primaryDark, InvestigoUi.primary]
                  : const [Color(0xFF4B5563), Color(0xFF6B7280)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_statusIcon(value), color: Colors.white, size: 34),
              const SizedBox(height: 12),
              Text(
                _statusTitle(value),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                value.detail,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (value.daysRemaining > 0) ...[
                const SizedBox(height: 10),
                Text(
                  '${value.daysRemaining} day(s) remaining',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
              if (value.licenseExpiresAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Valid until: ${value.licenseExpiresAt!.toLocal().toString().split('.').first}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: InvestigoUi.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This installation code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'লাইসেন্স নেওয়ার সময় এই code-টি দিন। License এই installation-এর জন্যই valid হবে।',
                style: TextStyle(
                  color: InvestigoUi.muted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      value.deviceCode,
                      style: const TextStyle(
                        color: InvestigoUi.primaryDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy',
                    onPressed: () => _copyDeviceCode(value.deviceCode),
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: InvestigoUi.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Activate / Renew',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Signed yearly activation key paste করুন। Internet connection লাগবে না।',
                style: TextStyle(
                  color: InvestigoUi.muted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _activationController,
                minLines: 3,
                maxLines: 6,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Activation Key',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: InvestigoUi.primaryButtonStyle(),
                  onPressed: _activating ? null : _activate,
                  icon: _activating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.verified_rounded),
                  label: Text(
                    _activating ? 'Verifying...' : 'Verify & Activate',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD4E1FF)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.offline_bolt_rounded, color: InvestigoUi.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Trial শেষ হলে activation ছাড়া app-এর কোনো data, backup, export বা restore access থাকবে না। App uninstall করলে app-private local data মুছে যাবে এবং Android automatic restore বন্ধ থাকবে। Reinstall করলে নতুন 14-day trial শুরু হবে, কিন্তু আগের trial installation-এর backup নতুন trial-এ restore হবে না।',
                  style: TextStyle(
                    color: InvestigoUi.text,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
