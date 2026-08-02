class OfficerProfile {
  final String name;
  final String rank;
  final String beltNo;
  final String policeStation;
  final String district;
  final String courtName;
  final String mobile;
  final String cugMobile;
  final String whatsApp;
  final String email;
  final String psAddress;
  final String pinCode;
  final String defaultHospital;
  final String defaultMorgue;
  final String defaultFslOffice;
  final String defaultSdpoOffice;

  const OfficerProfile({
    required this.name,
    required this.rank,
    required this.beltNo,
    required this.policeStation,
    required this.district,
    required this.courtName,
    required this.mobile,
    required this.cugMobile,
    required this.whatsApp,
    required this.email,
    required this.psAddress,
    required this.pinCode,
    required this.defaultHospital,
    required this.defaultMorgue,
    required this.defaultFslOffice,
    required this.defaultSdpoOffice,
  });

  factory OfficerProfile.empty() => const OfficerProfile(
        name: '',
        rank: '',
        beltNo: '',
        policeStation: '',
        district: '',
        courtName: '',
        mobile: '',
        cugMobile: '',
        whatsApp: '',
        email: '',
        psAddress: '',
        pinCode: '',
        defaultHospital: '',
        defaultMorgue: '',
        defaultFslOffice: '',
        defaultSdpoOffice: '',
      );

  bool get isComplete =>
      name.trim().isNotEmpty &&
      rank.trim().isNotEmpty &&
      policeStation.trim().isNotEmpty &&
      district.trim().isNotEmpty;

  String get stationAndDistrict =>
      [policeStation.trim(), district.trim()].where((e) => e.isNotEmpty).join(', ');

  OfficerProfile copyWith({
    String? name,
    String? rank,
    String? beltNo,
    String? policeStation,
    String? district,
    String? courtName,
    String? mobile,
    String? cugMobile,
    String? whatsApp,
    String? email,
    String? psAddress,
    String? pinCode,
    String? defaultHospital,
    String? defaultMorgue,
    String? defaultFslOffice,
    String? defaultSdpoOffice,
  }) {
    return OfficerProfile(
      name: name ?? this.name,
      rank: rank ?? this.rank,
      beltNo: beltNo ?? this.beltNo,
      policeStation: policeStation ?? this.policeStation,
      district: district ?? this.district,
      courtName: courtName ?? this.courtName,
      mobile: mobile ?? this.mobile,
      cugMobile: cugMobile ?? this.cugMobile,
      whatsApp: whatsApp ?? this.whatsApp,
      email: email ?? this.email,
      psAddress: psAddress ?? this.psAddress,
      pinCode: pinCode ?? this.pinCode,
      defaultHospital: defaultHospital ?? this.defaultHospital,
      defaultMorgue: defaultMorgue ?? this.defaultMorgue,
      defaultFslOffice: defaultFslOffice ?? this.defaultFslOffice,
      defaultSdpoOffice: defaultSdpoOffice ?? this.defaultSdpoOffice,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'rank': rank,
        'beltNo': beltNo,
        'policeStation': policeStation,
        'district': district,
        'courtName': courtName,
        'mobile': mobile,
        'cugMobile': cugMobile,
        'whatsApp': whatsApp,
        'email': email,
        'psAddress': psAddress,
        'pinCode': pinCode,
        'defaultHospital': defaultHospital,
        'defaultMorgue': defaultMorgue,
        'defaultFslOffice': defaultFslOffice,
        'defaultSdpoOffice': defaultSdpoOffice,
      };

  factory OfficerProfile.fromJson(Map<String, dynamic> json) {
    return OfficerProfile(
      name: json['name'] ?? '',
      rank: json['rank'] ?? '',
      beltNo: json['beltNo'] ?? '',
      policeStation: json['policeStation'] ?? '',
      district: json['district'] ?? '',
      courtName: json['courtName'] ?? '',
      mobile: json['mobile'] ?? '',
      cugMobile: json['cugMobile'] ?? '',
      whatsApp: json['whatsApp'] ?? '',
      email: json['email'] ?? '',
      psAddress: json['psAddress'] ?? '',
      pinCode: json['pinCode'] ?? '',
      defaultHospital: json['defaultHospital'] ?? '',
      defaultMorgue: json['defaultMorgue'] ?? '',
      defaultFslOffice: json['defaultFslOffice'] ?? '',
      defaultSdpoOffice: json['defaultSdpoOffice'] ?? '',
    );
  }
}
