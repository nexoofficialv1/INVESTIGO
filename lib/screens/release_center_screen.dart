import 'package:flutter/material.dart';

import '../core/app_language.dart';
import '../services/rc_feature_manifest.dart';

class ReleaseCenterScreen extends StatelessWidget {
  const ReleaseCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final included = RcFeatureManifest.included;
    final deferred = RcFeatureManifest.deferred;
    return Scaffold(
      appBar: AppBar(title: Text(L10n.t('RC-1 রিলিজ সেন্টার', 'RC-1 Release Center'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L10n.t('ফিচার ফ্রিজ সক্রিয়', 'Feature freeze active'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(L10n.t('RC-1 পর্যন্ত শুধু তালিকাভুক্ত ফিচারের bug fix, validation ও print calibration হবে।', 'Until RC-1, only bug fixes, validation and print calibration will be done for listed features.')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _section(context, L10n.t('RC-1-এ থাকবে', 'Included in RC-1'), included, Icons.check_circle, Colors.green),
          const SizedBox(height: 12),
          _section(context, L10n.t('পরবর্তী আপডেটে', 'Deferred to later'), deferred, Icons.schedule, Colors.orange),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<RcFeatureItem> items, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...items.map((item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(icon, color: color),
                  title: Text(L10n.t(item.titleBn, item.titleEn)),
                  subtitle: Text(item.domain),
                )),
          ],
        ),
      ),
    );
  }
}
