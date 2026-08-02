import 'package:flutter/material.dart';

import '../core/app_language.dart';
import '../core/app_theme.dart';
import '../models/officer_profile.dart';
import '../services/local_store_service.dart';
import 'backend_settings_screen.dart';
import 'backup_screen.dart';
import 'license_screen.dart';
import 'officer_profile_screen.dart';
import 'release_center_screen.dart';

class SettingsScreen extends StatefulWidget {
  final OfficerProfile profile;
  final ValueChanged<OfficerProfile> onProfileUpdated;

  const SettingsScreen({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalStoreService _store = LocalStoreService();
  late OfficerProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OfficerProfileScreen(
          profile: _profile,
          onSaved: (updated) async {
            await _store.saveOfficerProfile(updated);
            if (!mounted) return;
            setState(() => _profile = updated);
            widget.onProfileUpdated(updated);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _openBackup() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BackupScreen(profile: _profile)),
    );
  }

  Future<void> _openBackend() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BackendSettingsScreen(profile: _profile),
      ),
    );
  }

  Future<void> _openLicense() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LicenseScreen()),
    );
  }

  Future<void> _openReleaseCenter() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReleaseCenterScreen()),
    );
  }

  Future<void> _chooseLanguage() async {
    final selected = await showModalBottomSheet<AppLanguage>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('বাংলা'),
              onTap: () => Navigator.pop(context, AppLanguage.bengali),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('English'),
              onTap: () => Navigator.pop(context, AppLanguage.english),
            ),
          ],
        ),
      ),
    );
    if (selected != null) {
      await AppLanguageController.instance.setLanguage(selected);
      if (mounted) setState(() {});
    }
  }

  Widget _sectionTitle(String bn, String en) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(
          L10n.t(bn, en),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppTheme.deepGreen,
          ),
        ),
      );

  Widget _item({
    required IconData icon,
    required String titleBn,
    required String titleEn,
    required String subtitleBn,
    required String subtitleEn,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (color ?? AppTheme.deepGreen).withValues(alpha: .12),
          foregroundColor: color ?? AppTheme.deepGreen,
          child: Icon(icon),
        ),
        title: Text(
          L10n.t(titleBn, titleEn),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(L10n.t(subtitleBn, subtitleEn)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final station = _profile.policeStation.trim().isEmpty
        ? L10n.t('থানা সেট করা নেই', 'Police Station not set')
        : '${_profile.policeStation}, ${_profile.district}';

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: Text(L10n.t('সেটিংস', 'Settings'))),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            color: AppTheme.deepGreen,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _profile.name.trim().isEmpty
                        ? L10n.t('অফিসার প্রোফাইল', 'Officer Profile')
                        : '${_profile.rank} ${_profile.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    station,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _sectionTitle('অফিসার ও স্টেশন', 'Officer & Station'),
          _item(
            icon: Icons.badge_rounded,
            titleBn: 'প্রোফাইল',
            titleEn: 'Profile',
            subtitleBn: 'অফিসার, থানা, জেলা, কোর্ট, হাসপাতাল ও FSL তথ্য',
            subtitleEn: 'Officer, PS, district, court, hospital and FSL details',
            onTap: _openProfile,
          ),
          _sectionTitle('ডাটা ও সিস্টেম', 'Data & System'),
          _item(
            icon: Icons.backup_rounded,
            titleBn: 'ব্যাকআপ ও রিস্টোর',
            titleEn: 'Backup & Restore',
            subtitleBn: 'লোকাল ব্যাকআপ, শেয়ার ও পুনরুদ্ধার',
            subtitleEn: 'Local backup, share and restore',
            onTap: _openBackup,
            color: const Color(0xFF455A64),
          ),
          _item(
            icon: Icons.dns_rounded,
            titleBn: 'ব্যাকএন্ড',
            titleEn: 'Backend',
            subtitleBn: 'অফলাইন/অনলাইন মোড ও সার্ভার সেটআপ',
            subtitleEn: 'Offline/online mode and server setup',
            onTap: _openBackend,
            color: const Color(0xFF263238),
          ),
          _item(
            icon: Icons.workspace_premium_rounded,
            titleBn: 'লাইসেন্স',
            titleEn: 'License',
            subtitleBn: 'প্ল্যান, ফি ও অ্যাক্টিভেশন',
            subtitleEn: 'Plan, fee and activation',
            onTap: _openLicense,
            color: const Color(0xFF8D6E00),
          ),
          _sectionTitle('অ্যাপ', 'Application'),
          _item(
            icon: Icons.translate_rounded,
            titleBn: 'ভাষা',
            titleEn: 'Language',
            subtitleBn: 'বাংলা অথবা English নির্বাচন করুন',
            subtitleEn: 'Choose Bengali or English',
            onTap: _chooseLanguage,
            color: AppTheme.blue,
          ),
          _item(
            icon: Icons.verified_user_rounded,
            titleBn: 'RC-1 স্ট্যাটাস',
            titleEn: 'RC-1 Status',
            subtitleBn: 'ফিচার ফ্রিজ ও রিলিজ প্রস্তুতি',
            subtitleEn: 'Feature freeze and release readiness',
            onTap: _openReleaseCenter,
            color: const Color(0xFF2E7D32),
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'INVESTIGO 1.8.0-rc.5 (186)',
              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
