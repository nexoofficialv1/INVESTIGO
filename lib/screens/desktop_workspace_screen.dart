import 'package:flutter/material.dart';

import '../core/app_language.dart';
import '../core/app_theme.dart';
import '../models/case_file.dart';
import '../models/officer_profile.dart';
import '../services/local_store_service.dart';
import 'backup_screen.dart';
import 'case_detail_screen.dart';
import 'case_form_screen.dart';
import 'final_case_documents_screen.dart';
import 'ncr_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import 'ud_case_screen.dart';

class DesktopWorkspaceScreen extends StatefulWidget {
  final OfficerProfile profile;

  const DesktopWorkspaceScreen({super.key, required this.profile});

  @override
  State<DesktopWorkspaceScreen> createState() => _DesktopWorkspaceScreenState();
}

class _DesktopWorkspaceScreenState extends State<DesktopWorkspaceScreen> {
  final LocalStoreService _store = LocalStoreService();

  late OfficerProfile _profile;
  List<CaseFile> _cases = [];
  int _selectedIndex = 0;
  int _totalCds = 0;
  int _pendingActions = 0;
  int _udCount = 0;
  int _ncrCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _load();
  }

  CaseFile? get _latestCase => _cases.isEmpty ? null : _cases.first;

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    final cases = await _store.loadCases();
    var totalCds = 0;
    var pendingActions = 0;
    for (final file in cases) {
      totalCds += (await _store.loadCds(file.id)).length;
      pendingActions +=
          (await _store.loadPendingCdActions(file.id)).length;
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
      _loading = false;
    });
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    await _load();
  }

  Future<void> _newCase() async {
    await _open(CaseFormScreen(profile: _profile));
  }

  Future<void> _openCase(CaseFile file) async {
    await _open(CaseDetailScreen(profile: _profile, caseFile: file));
  }

  void _needCase() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          L10n.t('প্রথমে একটি মামলা তৈরি করুন।', 'Create a case first.'),
        ),
      ),
    );
  }

  Future<void> _openLatestCase() async {
    final file = _latestCase;
    if (file == null) {
      _needCase();
      return;
    }
    await _openCase(file);
  }

  Future<void> _openFinalDocuments() async {
    final file = _latestCase;
    if (file == null) {
      _needCase();
      return;
    }
    await _open(
      FinalCaseDocumentsScreen(profile: _profile, caseFile: file),
    );
  }

  Future<void> _openReport() async {
    await _open(ReportScreen(profile: _profile, caseFile: _latestCase));
  }

  Future<void> _openSettings() async {
    await _open(
      SettingsScreen(
        profile: _profile,
        onProfileUpdated: (updated) {
          if (!mounted) return;
          setState(() => _profile = updated);
        },
      ),
    );
  }

  Future<void> _chooseLanguage() async {
    final selected = await showDialog<AppLanguage>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.t('ভাষা নির্বাচন', 'Choose language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<AppLanguage>(
              value: AppLanguage.bengali,
              groupValue: AppLanguageController.instance.current,
              title: const Text('বাংলা'),
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<AppLanguage>(
              value: AppLanguage.english,
              groupValue: AppLanguageController.instance.current,
              title: const Text('English'),
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
      ),
    );
    if (selected != null) {
      await AppLanguageController.instance.setLanguage(selected);
    }
  }

  List<_DesktopMenuItem> get _menuItems => [
        _DesktopMenuItem(
          label: L10n.t('ড্যাশবোর্ড', 'Dashboard'),
          icon: Icons.dashboard_rounded,
        ),
        _DesktopMenuItem(
          label: L10n.t('মামলা', 'Cases'),
          icon: Icons.folder_copy_rounded,
        ),
        _DesktopMenuItem(
          label: L10n.t('CD ও নথি', 'CD & Documents'),
          icon: Icons.menu_book_rounded,
        ),
        _DesktopMenuItem(
          label: L10n.t('রিপোর্ট', 'Reports'),
          icon: Icons.summarize_rounded,
        ),
        const _DesktopMenuItem(label: 'UD', icon: Icons.assignment_rounded),
        const _DesktopMenuItem(label: 'NCR', icon: Icons.table_chart_rounded),
        _DesktopMenuItem(
          label: L10n.t('ব্যাকআপ', 'Backup'),
          icon: Icons.backup_rounded,
        ),
        _DesktopMenuItem(
          label: L10n.t('সেটিংস', 'Settings'),
          icon: Icons.settings_rounded,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final expanded = constraints.maxWidth >= 1120;
          return Row(
            children: [
              _sidebar(expanded),
              Expanded(
                child: Column(
                  children: [
                    _topBar(),
                    Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: KeyedSubtree(
                                key: ValueKey(_selectedIndex),
                                child: _buildPane(),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sidebar(bool expanded) {
    final items = _menuItems;
    return Container(
      width: expanded ? 250 : 86,
      color: AppTheme.deepGreen,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment:
                    expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.deepGreen,
                    child: Icon(Icons.policy_rounded),
                  ),
                  if (expanded) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INVESTIGO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Desktop RC',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final selected = index == _selectedIndex;
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    child: Material(
                      color: selected
                          ? Colors.white.withOpacity(0.16)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _selectedIndex = index),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: expanded ? 14 : 10,
                            vertical: 13,
                          ),
                          child: Row(
                            mainAxisAlignment: expanded
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.center,
                            children: [
                              Icon(
                                items[index].icon,
                                color: selected ? Colors.white : Colors.white70,
                              ),
                              if (expanded) ...[
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Text(
                                    items[index].label,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : Colors.white70,
                                      fontWeight: selected
                                          ? FontWeight.w900
                                          : FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                expanded ? 'v1.8.0 RC • build 195' : 'v195',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Material(
      color: Colors.white,
      elevation: 1,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _menuItems[_selectedIndex].label,
                        style: const TextStyle(
                          color: AppTheme.textDark,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_profile.rank} ${_profile.name} • '
                        '${_profile.policeStation}, ${_profile.district}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: L10n.t('রিফ্রেশ', 'Refresh'),
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                ),
                IconButton(
                  tooltip: L10n.t('ভাষা', 'Language'),
                  onPressed: _chooseLanguage,
                  icon: const Icon(Icons.translate_rounded),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _newCase,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(L10n.t('নতুন মামলা', 'New Case')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPane() {
    switch (_selectedIndex) {
      case 1:
        return _casesPane();
      case 2:
        return _documentsPane();
      case 3:
        return _modulePane(
          icon: Icons.summarize_rounded,
          title: L10n.t('Official Reports', 'Official Reports'),
          description: _latestCase == null
              ? L10n.t(
                  'General report খুলুন; case-based report-এর জন্য মামলা তৈরি করুন।',
                  'Open general reports; create a case for case-based reports.',
                )
              : '${L10n.t('সর্বশেষ মামলা', 'Latest case')}: '
                  '${_latestCase!.displayTitle}',
          actionLabel: L10n.t('Report Desk খুলুন', 'Open Report Desk'),
          onOpen: _openReport,
        );
      case 4:
        return _modulePane(
          icon: Icons.assignment_rounded,
          title: L10n.t('UD Case মডিউল', 'UD Case Module'),
          description: L10n.t(
            'UD entry, inquest এবং final report desktop window-তে খুলুন।',
            'Open UD entry, inquest and final report in the desktop window.',
          ),
          actionLabel: L10n.t('UD খুলুন', 'Open UD'),
          onOpen: () => _open(UdCaseScreen(profile: _profile)),
        );
      case 5:
        return _modulePane(
          icon: Icons.table_chart_rounded,
          title: L10n.t('NCR মডিউল', 'NCR Module'),
          description: L10n.t(
            'NCR prosecution report তৈরি, preview এবং export করুন।',
            'Create, preview and export NCR prosecution reports.',
          ),
          actionLabel: L10n.t('NCR খুলুন', 'Open NCR'),
          onOpen: () => _open(NcrScreen(profile: _profile)),
        );
      case 6:
        return _modulePane(
          icon: Icons.backup_rounded,
          title: L10n.t('Backup ও Restore', 'Backup & Restore'),
          description: L10n.t(
            'Local data export/import করে records নিরাপদ রাখুন।',
            'Export or import local data to protect records.',
          ),
          actionLabel: L10n.t('Backup খুলুন', 'Open Backup'),
          onOpen: () => _open(BackupScreen(profile: _profile)),
        );
      case 7:
        return _settingsPane();
      default:
        return _overviewPane();
    }
  }

  Widget _overviewPane() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _summaryCard(
                L10n.t('মামলা', 'Cases'),
                '${_cases.length}',
                Icons.folder_copy_rounded,
              ),
              _summaryCard('CD', '$_totalCds', Icons.menu_book_rounded),
              _summaryCard(
                L10n.t('Pending', 'Pending'),
                '$_pendingActions',
                Icons.pending_actions_rounded,
              ),
              _summaryCard('UD', '$_udCount', Icons.assignment_rounded),
              _summaryCard('NCR', '$_ncrCount', Icons.table_chart_rounded),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            L10n.t('দ্রুত কাজ', 'Quick Actions'),
            style: const TextStyle(
              color: AppTheme.textDark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _ActionCard(
                icon: Icons.add_box_rounded,
                title: L10n.t('নতুন মামলা', 'New Case'),
                subtitle: L10n.t('Case entry শুরু করুন', 'Start case entry'),
                onTap: _newCase,
              ),
              _ActionCard(
                icon: Icons.menu_book_rounded,
                title: 'Case Diary',
                subtitle: L10n.t('সর্বশেষ মামলা খুলুন', 'Open latest case'),
                onTap: _openLatestCase,
              ),
              _ActionCard(
                icon: Icons.picture_as_pdf_rounded,
                title: L10n.t('Final Documents', 'Final Documents'),
                subtitle: 'Preview • PDF • DOC',
                onTap: _openFinalDocuments,
              ),
              _ActionCard(
                icon: Icons.summarize_rounded,
                title: L10n.t('রিপোর্ট', 'Reports'),
                subtitle: 'SP • SDPO • SDO',
                onTap: _openReport,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _recentCases(),
        ],
      ),
    );
  }

  Widget _casesPane() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: const Icon(
                Icons.folder_copy_rounded,
                color: AppTheme.deepGreen,
              ),
              title: Text(
                L10n.t('মামলার তালিকা', 'Case Register'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                L10n.t(
                  'মামলা খুলে CD, statement, forms ও evidence পরিচালনা করুন।',
                  'Open a case to manage CD, statements, forms and evidence.',
                ),
              ),
              trailing: FilledButton.icon(
                onPressed: _newCase,
                icon: const Icon(Icons.add),
                label: Text(L10n.t('নতুন মামলা', 'New Case')),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _cases.isEmpty
                  ? _emptyCases()
                  : ListView.separated(
                      itemCount: _cases.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) =>
                          _caseTile(_cases[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _documentsPane() {
    final file = _latestCase;
    return _modulePane(
      icon: Icons.menu_book_rounded,
      title: L10n.t('CD ও Final Documents', 'CD & Final Documents'),
      description: file == null
          ? L10n.t(
              'CD, Preview, PDF ও DOC ব্যবহার করতে প্রথমে একটি মামলা তৈরি করুন।',
              'Create a case before using CD, Preview, PDF and DOC.',
            )
          : '${L10n.t('সর্বশেষ মামলা', 'Latest case')}: ${file.displayTitle}',
      actionLabel: file == null
          ? L10n.t('নতুন মামলা', 'New Case')
          : L10n.t('Case Diary খুলুন', 'Open Case Diary'),
      onOpen: file == null ? _newCase : _openLatestCase,
      secondaryActions: file == null
          ? const []
          : [
              OutlinedButton.icon(
                onPressed: _openFinalDocuments,
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('Preview / PDF / DOC'),
              ),
            ],
    );
  }

  Widget _settingsPane() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 38,
                    backgroundColor: AppTheme.deepGreen,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.local_police_rounded, size: 38),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${_profile.rank} ${_profile.name}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${_profile.policeStation} • ${_profile.district}',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: _openSettings,
                        icon: const Icon(Icons.settings_rounded),
                        label: Text(
                          L10n.t('সেটিংস খুলুন', 'Open Settings'),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _chooseLanguage,
                        icon: const Icon(Icons.translate_rounded),
                        label: Text(L10n.t('ভাষা', 'Language')),
                      ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _open(BackupScreen(profile: _profile)),
                        icon: const Icon(Icons.backup_rounded),
                        label: Text(L10n.t('ব্যাকআপ', 'Backup')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modulePane({
    required IconData icon,
    required String title,
    required String description,
    required String actionLabel,
    required VoidCallback onOpen,
    List<Widget> secondaryActions = const [],
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(38),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: AppTheme.deepGreen,
                    foregroundColor: Colors.white,
                    child: Icon(icon, size: 42),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: onOpen,
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: Text(actionLabel),
                      ),
                      ...secondaryActions,
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return SizedBox(
      width: 190,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.deepGreen,
                foregroundColor: Colors.white,
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentCases() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
            title: Text(
              L10n.t('সাম্প্রতিক মামলা', 'Recent Cases'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            trailing: TextButton(
              onPressed: () => setState(() => _selectedIndex = 1),
              child: Text(L10n.t('সব দেখুন', 'View all')),
            ),
          ),
          const Divider(height: 1),
          if (_cases.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: _emptyCases(),
            )
          else
            ..._cases.take(5).map(_caseTile),
        ],
      ),
    );
  }

  Widget _caseTile(CaseFile file) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      leading: const CircleAvatar(
        backgroundColor: AppTheme.deepGreen,
        foregroundColor: Colors.white,
        child: Icon(Icons.folder_open_rounded),
      ),
      title: Text(
        file.displayTitle,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        '${L10n.t('ধারা', 'Sections')}: ${file.sections}\n'
        '${L10n.t('অভিযোগকারী', 'Complainant')}: ${file.complainantName}',
        maxLines: 2,
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => _openCase(file),
    );
  }

  Widget _emptyCases() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.create_new_folder_outlined,
            size: 54,
            color: Colors.black38,
          ),
          const SizedBox(height: 12),
          Text(
            L10n.t('কোনো মামলা নেই', 'No cases yet'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _newCase,
            icon: const Icon(Icons.add),
            label: Text(L10n.t('প্রথম মামলা তৈরি করুন', 'Create first case')),
          ),
        ],
      ),
    );
  }
}

class _DesktopMenuItem {
  final String label;
  final IconData icon;

  const _DesktopMenuItem({required this.label, required this.icon});
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 245,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.deepGreen,
                  foregroundColor: Colors.white,
                  child: Icon(icon),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
