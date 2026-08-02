enum RcFeatureStatus { included, deferred, blocked }

class RcFeatureItem {
  const RcFeatureItem({
    required this.id,
    required this.titleBn,
    required this.titleEn,
    required this.status,
    required this.domain,
  });

  final String id;
  final String titleBn;
  final String titleEn;
  final RcFeatureStatus status;
  final String domain;
}

class RcFeatureManifest {
  const RcFeatureManifest._();

  static const items = <RcFeatureItem>[
    RcFeatureItem(id: 'case-cd', titleBn: 'দৈনিক কেস ডায়েরি', titleEn: 'Daily Case Diary', status: RcFeatureStatus.included, domain: 'Regular Case'),
    RcFeatureItem(id: 'case-final-cd', titleBn: 'ফাইনাল সিডি', titleEn: 'Final CD', status: RcFeatureStatus.included, domain: 'Regular Case'),
    RcFeatureItem(id: 'case-cs', titleBn: 'চার্জশিট', titleEn: 'Charge Sheet', status: RcFeatureStatus.included, domain: 'Regular Case'),
    RcFeatureItem(id: 'case-if5', titleBn: 'IF-5 / ফাইনাল ফর্ম', titleEn: 'IF-5 / Final Form', status: RcFeatureStatus.included, domain: 'Regular Case'),
    RcFeatureItem(id: 'case-map', titleBn: 'স্কেচ ম্যাপ ও ইনডেক্স', titleEn: 'Sketch Map and Index', status: RcFeatureStatus.included, domain: 'Regular Case'),
    RcFeatureItem(id: 'case-assistant', titleBn: 'অফলাইন তদন্ত সহকারী', titleEn: 'Offline Investigation Assistant', status: RcFeatureStatus.included, domain: 'Regular Case'),
    RcFeatureItem(id: 'ud-inquest', titleBn: 'ইনকোয়েস্ট / সুরতহাল', titleEn: 'Inquest / Surathal', status: RcFeatureStatus.included, domain: 'UD'),
    RcFeatureItem(id: 'ud-challan', titleBn: 'ডেড বডি চালান (ফর্ম ৫৩৭১)', titleEn: 'Dead Body Challan (Form 5371)', status: RcFeatureStatus.included, domain: 'UD'),
    RcFeatureItem(id: 'ud-final', titleBn: 'UD ফাইনাল রিপোর্ট (ফর্ম ৫৩৭০)', titleEn: 'UD Final Report (Form 5370)', status: RcFeatureStatus.included, domain: 'UD'),
    RcFeatureItem(id: 'ncr', titleBn: 'NCR ল্যান্ডস্কেপ রিপোর্ট', titleEn: 'NCR Landscape Report', status: RcFeatureStatus.included, domain: 'NCR'),
    RcFeatureItem(id: 'court', titleBn: 'কোর্ট ট্র্যাকিং', titleEn: 'Court Tracking', status: RcFeatureStatus.deferred, domain: 'Future'),
    RcFeatureItem(id: 'malkhana', titleBn: 'মালখানা ও সম্পত্তি লাইফসাইকেল', titleEn: 'Malkhana and Property Lifecycle', status: RcFeatureStatus.deferred, domain: 'Future'),
    RcFeatureItem(id: 'sync', titleBn: 'অনলাইন সিঙ্ক', titleEn: 'Online Sync', status: RcFeatureStatus.deferred, domain: 'Future'),
    RcFeatureItem(id: 'intelligence', titleBn: 'কেস ইন্টেলিজেন্স', titleEn: 'Case Intelligence', status: RcFeatureStatus.deferred, domain: 'Future'),
  ];

  static List<RcFeatureItem> get included => items.where((e) => e.status == RcFeatureStatus.included).toList(growable: false);
  static List<RcFeatureItem> get deferred => items.where((e) => e.status == RcFeatureStatus.deferred).toList(growable: false);
}
