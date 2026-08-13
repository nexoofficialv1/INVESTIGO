import 'package:flutter/material.dart';

import '../core/app_language.dart';
import '../models/case_file.dart';
import '../models/officer_profile.dart';
import '../services/local_store_service.dart';
import '../widgets/investigo_ui.dart';
import 'backend_settings_screen.dart';
import 'backup_screen.dart';
import 'case_detail_screen.dart';
import 'case_form_screen.dart';
import 'case_parser_screen.dart';
import 'case_register_screen.dart';
import 'compliance_screen.dart';
import 'evidence_screen.dart';
import 'final_case_documents_screen.dart';
import 'forms_screen.dart';
import 'investigation_checklist_screen.dart';
import 'investigation_screen.dart';
import 'legal_reference_screen.dart';
import 'license_screen.dart';
import 'ncr_screen.dart';
import 'officer_profile_screen.dart';
import 'release_center_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import 'sketch_map_screen.dart';
import 'sop_compliance_screen.dart';
import 'statement_screen.dart';
import 'ud_case_workflow_screen.dart';

class DashboardScreen extends StatefulWidget {
  final OfficerProfile profile;

  const DashboardScreen({super.key, required this.profile});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LocalStoreService _store = LocalStoreService();
  late OfficerProfile _profile;
  List<CaseFile> _cases = [];
  int _tabIndex = 0;
  int _totalCds = 0;
  int _pendingActions = 0;
  int _udCount = 0;
  int _ncrCount = 0;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _load();
  }

  Future<void> _load() async {
    final cases = await _store.loadCases();
    var totalCds = 0;
    var pendingActions = 0;
    for (final file in cases) {
      totalCds += (await _store.loadCds(file.id)).length;
      pendingActions += (await _store.loadPendingCdActions(file.id)).length;
    }
    final udCases = await _store.loadUdCases();
    final ncrReports = await _store.loadNcrReports();
    if (!mounted) return;
    setState(() {
      _cases = cases;
      _totalCds = totalCds;
      _pendingActions = pendingActions;
      _udCount = udCases.length;
      _ncrCount = ncrReports.length;
    });
  }

  CaseFile? get _latestCase => _cases.isEmpty ? null : _cases.first;

  Future<void> _newCase() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CaseFormScreen(profile: _profile)),
    );
    await _load();
  }

  void _needCaseMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(L10n.t(
          'প্রথমে একটি মামলা তৈরি করুন।',
          'Create a case first.',
        )),
      ),
    );
  }

  Future<void> _openCaseRegister() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CaseRegisterScreen(profile: _profile)),
    );
    await _load();
  }

  Future<void> _openCdWriter() async {
    final file = _latestCase;
    if (file == null) {
      await _newCase();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaseDetailScreen(profile: _profile, caseFile: file),
      ),
    );
    await _load();
  }

  Future<void> _openForms() async {
    final file = _latestCase;
    if (file == null) {
      _needCaseMessage();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormsScreen(profile: _profile, caseFile: file),
      ),
    );
  }

  Future<void> _openStatements() async {
    final file = _latestCase;
    if (file == null) {
      _needCaseMessage();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatementScreen(profile: _profile, caseFile: file),
      ),
    );
  }

  Future<void> _openSketchMap() async {
    final file = _latestCase;
    if (file == null) {
      _needCaseMessage();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SketchMapScreen(profile: _profile, caseFile: file),
      ),
    );
    await _load();
  }

  Future<void> _openInvestigation() async {
    final file = _latestCase;
    if (file == null) {
      _needCaseMessage();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvestigationScreen(profile: _profile, caseFile: file),
      ),
    );
    await _load();
  }

  Future<void> _openEvidence() async {
    final file = _latestCase;
    if (file == null) {
      _needCaseMessage();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EvidenceScreen(profile: _profile, caseFile: file),
      ),
    );
  }

  Future<void> _openFinalCaseDocuments() async {
    final file = _latestCase;
    if (file == null) {
      _needCaseMessage();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FinalCaseDocumentsScreen(
          profile: _profile,
          caseFile: file,
        ),
      ),
    );
    await _load();
  }

  Future<void> _openReport() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportScreen(profile: _profile, caseFile: null),
      ),
    );
  }

  Future<void> _openCaseParser() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CaseParserScreen(profile: _profile)),
    );
    await _load();
  }

  Future<void> _openCompliance() async {
    final file = _latestCase;
    if (file == null) {
      _needCaseMessage();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ComplianceScreen(caseFile: file)),
    );
  }

  Future<void> _openInvestigationChecklist() async {
    final file = _latestCase;
    if (file == null) {
      _needCaseMessage();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvestigationChecklistScreen(caseFile: file),
      ),
    );
  }

  Future<void> _openSopCompliance() async {
    final file = _latestCase;
    if (file == null) {
      _needCaseMessage();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SopComplianceScreen(caseFile: file)),
    );
  }

  Future<void> _openLegalReference() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LegalReferenceScreen()),
    );
  }

  Future<void> _openUdCase() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UdCaseWorkflowScreen(profile: _profile)),
    );
  }

  Future<void> _openNcr() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NcrScreen(profile: _profile)),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          profile: _profile,
          onProfileUpdated: (updated) {
            if (!mounted) return;
            setState(() => _profile = updated);
          },
        ),
      ),
    );
    await _load();
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

  Future<void> _openBackendSettings() async {
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
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const InvestigoPageTitle(
                title: 'ভাষা নির্বাচন করুন',
                subtitle: 'Select language',
              ),
              const SizedBox(height: 12),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                tileColor: InvestigoUi.background,
                leading: const Icon(Icons.translate),
                title: const Text('বাংলা'),
                onTap: () => Navigator.pop(context, AppLanguage.bengali),
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                tileColor: InvestigoUi.background,
                leading: const Icon(Icons.language),
                title: const Text('English'),
                onTap: () => Navigator.pop(context, AppLanguage.english),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) {
      await AppLanguageController.instance.setLanguage(selected);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InvestigoUi.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: InvestigoUi.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'INVESTIGO',
          style: TextStyle(
            color: InvestigoUi.primaryDark,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
        actions: [
          IconButton(
            tooltip: L10n.t('ভাষা', 'Language'),
            onPressed: _chooseLanguage,
            icon: const Icon(Icons.translate_rounded),
          ),
          IconButton(
            tooltip: L10n.t('প্রোফাইল', 'Profile'),
            onPressed: _openProfile,
            icon: const Icon(Icons.account_circle_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            _welcomeCard(),
            const SizedBox(height: 18),
            InvestigoPageTitle(
              title: L10n.t('আজকের কাজ', "Today's Work"),
              subtitle: L10n.t(
                'বড় বাটনে চাপুন — এক ধাপ করে কাজ হবে',
                'Tap a large button and follow one step at a time',
              ),
            ),
            const SizedBox(height: 12),
            _primaryGrid(),
            const SizedBox(height: 20),
            InvestigoPageTitle(
              title: L10n.t('এক নজরে', 'At a glance'),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 76,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  InvestigoStatPill(
                    value: '${_cases.length}',
                    label: L10n.t('মামলা', 'Cases'),
                    icon: Icons.folder_copy_outlined,
                  ),
                  const SizedBox(width: 9),
                  InvestigoStatPill(
                    value: '$_totalCds',
                    label: 'CD',
                    icon: Icons.menu_book_outlined,
                  ),
                  const SizedBox(width: 9),
                  InvestigoStatPill(
                    value: '$_pendingActions',
                    label: L10n.t('বাকি কাজ', 'Pending'),
                    icon: Icons.schedule_outlined,
                  ),
                  const SizedBox(width: 9),
                  InvestigoStatPill(
                    value: '$_udCount',
                    label: 'UD',
                    icon: Icons.assignment_outlined,
                  ),
                  const SizedBox(width: 9),
                  InvestigoStatPill(
                    value: '$_ncrCount',
                    label: 'NCR',
                    icon: Icons.table_chart_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _moreTools(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-case',
        backgroundColor: InvestigoUi.primary,
        foregroundColor: Colors.white,
        onPressed: _newCase,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          L10n.t('নতুন মামলা', 'New Case'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) {
          setState(() => _tabIndex = index);
          if (index == 1) _openCaseRegister();
          if (index == 2) _openLegalReference();
          if (index == 3) _openSettings();
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: L10n.t('হোম', 'Home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.folder_outlined),
            selectedIcon: const Icon(Icons.folder_rounded),
            label: L10n.t('মামলা', 'Cases'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.gavel_outlined),
            selectedIcon: const Icon(Icons.gavel_rounded),
            label: L10n.t('আইন', 'Law'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: L10n.t('সেটিংস', 'Settings'),
          ),
        ],
      ),
    );
  }

  Widget _welcomeCard() {
    final name = _profile.name.trim().isEmpty ? L10n.t('অফিসার', 'Officer') : _profile.name.trim();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [InvestigoUi.primaryDark, InvestigoUi.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x302447D8),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.local_police_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L10n.t('স্বাগতম, $name', 'Welcome, $name'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_profile.rank} • ${_profile.policeStation}\n${_profile.district}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _openSettings,
            color: Colors.white,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  Widget _primaryGrid() {
    final items = <InvestigoActionCard>[
      InvestigoActionCard(
        icon: Icons.add_box_outlined,
        title: L10n.t('কেস এন্ট্রি', 'Case Entry'),
        subtitle: L10n.t('নতুন মামলা লিখুন', 'Create a new case'),
        onTap: _newCase,
      ),
      InvestigoActionCard(
        icon: Icons.menu_book_outlined,
        title: L10n.t('সিডি তৈরি', 'Create CD'),
        subtitle: L10n.t('ধাপে ধাপে Case Diary', 'Guided Case Diary'),
        onTap: _openCdWriter,
        iconColor: InvestigoUi.accent,
      ),
      InvestigoActionCard(
        icon: Icons.groups_outlined,
        title: L10n.t('সাক্ষীর বিবৃতি', 'Statements'),
        subtitle: L10n.t('একাধিক সাক্ষী যোগ করুন', 'Add multiple witnesses'),
        onTap: _openStatements,
      ),
      InvestigoActionCard(
        icon: Icons.description_outlined,
        title: L10n.t('ফর্ম ও নোটিশ', 'Forms & Notices'),
        subtitle: L10n.t('সহজ guided form', 'Simple guided forms'),
        onTap: _openForms,
        iconColor: const Color(0xFF8B5CF6),
      ),
      InvestigoActionCard(
        icon: Icons.map_outlined,
        title: L10n.t('স্কেচ ম্যাপ', 'Sketch Map'),
        subtitle: L10n.t('Auto draft + approval', 'Auto draft + approval'),
        onTap: _openSketchMap,
        iconColor: const Color(0xFF0E8A72),
      ),
      InvestigoActionCard(
        icon: Icons.search_rounded,
        title: L10n.t('কেস খুঁজুন', 'Search Case'),
        subtitle: L10n.t('নাম/নম্বর/ধারা', 'Name / No. / section'),
        onTap: _openCaseRegister,
      ),
      InvestigoActionCard(
        icon: Icons.fact_check_outlined,
        title: L10n.t('ফাইনাল রিপোর্ট / CS', 'Final Report / CS'),
        subtitle: L10n.t('Last CD থেকে তৈরি', 'Generate from final CD'),
        onTap: _openFinalCaseDocuments,
        iconColor: const Color(0xFFE67E22),
      ),
      InvestigoActionCard(
        icon: Icons.gavel_outlined,
        title: L10n.t('BNS / BNSS', 'BNS / BNSS'),
        subtitle: L10n.t('ধারা ও সহজ ব্যাখ্যা', 'Sections & easy meaning'),
        onTap: _openLegalReference,
        iconColor: const Color(0xFF475467),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: .98,
      ),
      itemCount: items.length,
      itemBuilder: (_, index) => items[index],
    );
  }

  Widget _moreTools() {
    final tools = <_SimpleTool>[
      _SimpleTool(Icons.manage_search_outlined, L10n.t('তদন্ত', 'Investigation'), _openInvestigation),
      _SimpleTool(Icons.inventory_2_outlined, L10n.t('প্রমাণ', 'Evidence'), _openEvidence),
      _SimpleTool(Icons.checklist_outlined, L10n.t('চেকলিস্ট', 'Checklist'), _openInvestigationChecklist),
      _SimpleTool(Icons.policy_outlined, 'SOP', _openSopCompliance),
      _SimpleTool(Icons.summarize_outlined, L10n.t('রিপোর্ট', 'Reports'), _openReport),
      _SimpleTool(Icons.document_scanner_outlined, L10n.t('কেস পার্সার', 'Case Parser'), _openCaseParser),
      _SimpleTool(Icons.assignment_outlined, 'UD', _openUdCase),
      _SimpleTool(Icons.table_chart_outlined, 'NCR', _openNcr),
      _SimpleTool(Icons.event_available_outlined, L10n.t('কমপ্লায়েন্স', 'Compliance'), _openCompliance),
      _SimpleTool(Icons.backup_outlined, L10n.t('ব্যাকআপ', 'Backup'), _openBackup),
      _SimpleTool(Icons.dns_outlined, L10n.t('ব্যাকএন্ড', 'Backend'), _openBackendSettings),
      _SimpleTool(Icons.new_releases_outlined, L10n.t('রিলিজ', 'Release'), _openReleaseCenter),
      _SimpleTool(Icons.verified_user_outlined, L10n.t('লাইসেন্স', 'License'), _openLicense),
    ];

    return Container(
      decoration: InvestigoUi.cardDecoration(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L10n.t('আরও দরকারি কাজ', 'More tools'),
            style: const TextStyle(
              color: InvestigoUi.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ...tools.map(
            (tool) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: InvestigoUi.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tool.icon, color: InvestigoUi.primary, size: 21),
              ),
              title: Text(
                tool.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: tool.onTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleTool {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SimpleTool(this.icon, this.title, this.onTap);
}
