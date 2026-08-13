import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'core/app_language.dart';
import 'core/platform_info.dart';
import 'models/officer_profile.dart';
import 'screens/dashboard_screen.dart';
import 'screens/desktop_workspace_screen.dart';
import 'screens/officer_profile_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/license_screen.dart';
import 'services/local_store_service.dart';
import 'services/offline_license_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLanguageController.instance.load();
  runApp(const InvestigationProcessApp());
}

class InvestigationProcessApp extends StatelessWidget {
  const InvestigationProcessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLanguageController.instance,
      builder: (context, language, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'INVESTIGO',
        locale: language == AppLanguage.bengali
            ? const Locale('bn', 'IN')
            : const Locale('en', 'IN'),
        theme: AppTheme.light(),
        home: const StartupGate(),
      ),
    );
  }
}

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  final LocalStoreService _store = LocalStoreService();
  final OfflineLicenseService _licenseService = OfflineLicenseService();
  OfficerProfile? _profile;
  OfflineLicenseSnapshot? _license;
  bool _loading = true;
  bool _introDone = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _store.loadOfficerProfile();
    final license = await _licenseService.evaluate();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _license = license;
      _loading = false;
    });
  }

  Future<void> _refreshLicense() async {
    final license = await _licenseService.evaluate();
    if (!mounted) return;
    setState(() => _license = license);
  }

  @override
  Widget build(BuildContext context) {
    if (!_introDone) {
      return IntroScreen(onStart: () => setState(() => _introDone = true));
    }
    if (_loading || _license == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_license!.canUseApp) {
      return LicenseScreen(
        allowBack: false,
        onLicenseChanged: _refreshLicense,
      );
    }
    final profile = _profile;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!profile.isComplete) {
      return OfficerProfileScreen(
        profile: profile,
        onSaved: (updated) async {
          await _store.saveOfficerProfile(updated);
          if (!mounted) return;
          setState(() => _profile = updated);
        },
      );
    }
    return isDesktopRuntime
        ? DesktopWorkspaceScreen(profile: profile)
        : DashboardScreen(profile: profile);
  }
}
