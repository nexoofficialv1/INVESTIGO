class OfficerProfile {
  final String name;
  final String rank;
  final String beltNo;
  final String policeStation;
  final String district;
  final String courtName;
  final String mobile;
  final String email;

  const OfficerProfile({
    required this.name,
    required this.rank,
    required this.beltNo,
    required this.policeStation,
    required this.district,
    required this.courtName,
    required this.mobile,
    required this.email,
  });

  factory OfficerProfile.empty() => const OfficerProfile(
        name: '',
        rank: '',
        beltNo: '',
        policeStation: 'Kalna Police Station',
        district: 'Purba Bardhaman',
        courtName: 'Ld. ACJM Court, Kalna',
        mobile: '',
        email: '',
      );

  bool get isComplete => name.trim().isNotEmpty && rank.trim().isNotEmpty;

  OfficerProfile copyWith({
    String? name,
    String? rank,
    String? beltNo,
    String? policeStation,
    String? district,
    String? courtName,
    String? mobile,
    String? email,
  }) {
    return OfficerProfile(
      name: name ?? this.name,
      rank: rank ?? this.rank,
      beltNo: beltNo ?? this.beltNo,
      policeStation: policeStation ?? this.policeStation,
      district: district ?? this.district,
      courtName: courtName ?? this.courtName,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
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
        'email': email,
      };

  factory OfficerProfile.fromJson(Map<String, dynamic> json) {
    return OfficerProfile(
      name: json['name'] ?? '',
      rank: json['rank'] ?? '',
      beltNo: json['beltNo'] ?? '',
      policeStation: json['policeStation'] ?? 'Kalna Police Station',
      district: json['district'] ?? 'Purba Bardhaman',
      courtName: json['courtName'] ?? 'Ld. ACJM Court, Kalna',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
    );
  }
}
