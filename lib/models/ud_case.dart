class UdCase {
  final String id;
  final String district;
  final String policeStation;
  final String udNo;
  final String gdeNo;
  final String dateTime;
  final String distanceFromPs;
  final String directionFromPs;
  final String placeFound;
  final String longitude;
  final String latitude;
  final String deadBodyFoundDate;
  final String deadBodyFoundTime;
  final String informantName;
  final String informantAge;
  final String informantSex;
  final String informantAddress;
  final String identifiedByName;
  final String identifiedByAge;
  final String identifiedBySex;
  final String identifiedByRelation;
  final String identifiedByAddress;
  final String deceasedName;
  final String deceasedSex;
  final String deceasedAge;
  final String deceasedAddress;
  final String bodyPosition;
  final String build;
  final String height;
  final String rigorMortis;
  final String complexion;
  final String deformities;
  final String religionRaceCommunity;
  final String teeth;
  final String eyes;
  final String laceDerma;
  final String mole;
  final String tattoo;
  final String dress;
  final String otherFeatures;
  final String injuryHead;
  final String injuryFace;
  final String injuryNeck;
  final String injuryChest;
  final String injuryStomach;
  final String injuryShoulder;
  final String injuryRightHand;
  final String injuryLeftHand;
  final String injuryRightLeg;
  final String injuryLeftLeg;
  final String injuryPrivateParts;
  final String injuryBack;
  final String injuryOther;
  final String nostrils;
  final String earsEyes;
  final String mouth;
  final String penisVagina;
  final String anus;
  final String weaponOpinion;
  final String ligatureDescription;
  final String foreignMaterial;
  final String poDescription;
  final String articlesAtPo;
  final String probableCauseOfDeath;
  final String remarks;
  final String witness1NameAddress;
  final String witness2NameAddress;
  final String briefFacts;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UdCase({
    required this.id,
    required this.district,
    required this.policeStation,
    required this.udNo,
    required this.gdeNo,
    required this.dateTime,
    required this.distanceFromPs,
    required this.directionFromPs,
    required this.placeFound,
    required this.longitude,
    required this.latitude,
    required this.deadBodyFoundDate,
    required this.deadBodyFoundTime,
    required this.informantName,
    required this.informantAge,
    required this.informantSex,
    required this.informantAddress,
    required this.identifiedByName,
    required this.identifiedByAge,
    required this.identifiedBySex,
    required this.identifiedByRelation,
    required this.identifiedByAddress,
    required this.deceasedName,
    required this.deceasedSex,
    required this.deceasedAge,
    required this.deceasedAddress,
    required this.bodyPosition,
    required this.build,
    required this.height,
    required this.rigorMortis,
    required this.complexion,
    required this.deformities,
    required this.religionRaceCommunity,
    required this.teeth,
    required this.eyes,
    required this.laceDerma,
    required this.mole,
    required this.tattoo,
    required this.dress,
    required this.otherFeatures,
    required this.injuryHead,
    required this.injuryFace,
    required this.injuryNeck,
    required this.injuryChest,
    required this.injuryStomach,
    required this.injuryShoulder,
    required this.injuryRightHand,
    required this.injuryLeftHand,
    required this.injuryRightLeg,
    required this.injuryLeftLeg,
    required this.injuryPrivateParts,
    required this.injuryBack,
    required this.injuryOther,
    required this.nostrils,
    required this.earsEyes,
    required this.mouth,
    required this.penisVagina,
    required this.anus,
    required this.weaponOpinion,
    required this.ligatureDescription,
    required this.foreignMaterial,
    required this.poDescription,
    required this.articlesAtPo,
    required this.probableCauseOfDeath,
    required this.remarks,
    required this.witness1NameAddress,
    required this.witness2NameAddress,
    required this.briefFacts,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UdCase.empty({String ps = '', String district = ''}) {
    final now = DateTime.now();
    return UdCase(
      id: 'ud_${now.microsecondsSinceEpoch}',
      district: district,
      policeStation: ps,
      udNo: '',
      gdeNo: '',
      dateTime: '',
      distanceFromPs: '',
      directionFromPs: '',
      placeFound: '',
      longitude: '',
      latitude: '',
      deadBodyFoundDate: '',
      deadBodyFoundTime: '',
      informantName: '',
      informantAge: '',
      informantSex: '',
      informantAddress: '',
      identifiedByName: '',
      identifiedByAge: '',
      identifiedBySex: '',
      identifiedByRelation: '',
      identifiedByAddress: '',
      deceasedName: '',
      deceasedSex: '',
      deceasedAge: '',
      deceasedAddress: '',
      bodyPosition: '',
      build: '',
      height: '',
      rigorMortis: '',
      complexion: '',
      deformities: '',
      religionRaceCommunity: '',
      teeth: '',
      eyes: '',
      laceDerma: '',
      mole: '',
      tattoo: '',
      dress: '',
      otherFeatures: '',
      injuryHead: '',
      injuryFace: '',
      injuryNeck: '',
      injuryChest: '',
      injuryStomach: '',
      injuryShoulder: '',
      injuryRightHand: '',
      injuryLeftHand: '',
      injuryRightLeg: '',
      injuryLeftLeg: '',
      injuryPrivateParts: '',
      injuryBack: '',
      injuryOther: '',
      nostrils: '',
      earsEyes: '',
      mouth: '',
      penisVagina: '',
      anus: '',
      weaponOpinion: '',
      ligatureDescription: '',
      foreignMaterial: '',
      poDescription: '',
      articlesAtPo: '',
      probableCauseOfDeath: '',
      remarks: '',
      witness1NameAddress: '',
      witness2NameAddress: '',
      briefFacts: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  String get displayTitle => udNo.trim().isEmpty ? 'New UD Case' : 'UD Case No. $udNo';

  UdCase copyWith(Map<String, String> v) => UdCase(
        id: id,
        district: v['district'] ?? district,
        policeStation: v['policeStation'] ?? policeStation,
        udNo: v['udNo'] ?? udNo,
        gdeNo: v['gdeNo'] ?? gdeNo,
        dateTime: v['dateTime'] ?? dateTime,
        distanceFromPs: v['distanceFromPs'] ?? distanceFromPs,
        directionFromPs: v['directionFromPs'] ?? directionFromPs,
        placeFound: v['placeFound'] ?? placeFound,
        longitude: v['longitude'] ?? longitude,
        latitude: v['latitude'] ?? latitude,
        deadBodyFoundDate: v['deadBodyFoundDate'] ?? deadBodyFoundDate,
        deadBodyFoundTime: v['deadBodyFoundTime'] ?? deadBodyFoundTime,
        informantName: v['informantName'] ?? informantName,
        informantAge: v['informantAge'] ?? informantAge,
        informantSex: v['informantSex'] ?? informantSex,
        informantAddress: v['informantAddress'] ?? informantAddress,
        identifiedByName: v['identifiedByName'] ?? identifiedByName,
        identifiedByAge: v['identifiedByAge'] ?? identifiedByAge,
        identifiedBySex: v['identifiedBySex'] ?? identifiedBySex,
        identifiedByRelation: v['identifiedByRelation'] ?? identifiedByRelation,
        identifiedByAddress: v['identifiedByAddress'] ?? identifiedByAddress,
        deceasedName: v['deceasedName'] ?? deceasedName,
        deceasedSex: v['deceasedSex'] ?? deceasedSex,
        deceasedAge: v['deceasedAge'] ?? deceasedAge,
        deceasedAddress: v['deceasedAddress'] ?? deceasedAddress,
        bodyPosition: v['bodyPosition'] ?? bodyPosition,
        build: v['build'] ?? build,
        height: v['height'] ?? height,
        rigorMortis: v['rigorMortis'] ?? rigorMortis,
        complexion: v['complexion'] ?? complexion,
        deformities: v['deformities'] ?? deformities,
        religionRaceCommunity: v['religionRaceCommunity'] ?? religionRaceCommunity,
        teeth: v['teeth'] ?? teeth,
        eyes: v['eyes'] ?? eyes,
        laceDerma: v['laceDerma'] ?? laceDerma,
        mole: v['mole'] ?? mole,
        tattoo: v['tattoo'] ?? tattoo,
        dress: v['dress'] ?? dress,
        otherFeatures: v['otherFeatures'] ?? otherFeatures,
        injuryHead: v['injuryHead'] ?? injuryHead,
        injuryFace: v['injuryFace'] ?? injuryFace,
        injuryNeck: v['injuryNeck'] ?? injuryNeck,
        injuryChest: v['injuryChest'] ?? injuryChest,
        injuryStomach: v['injuryStomach'] ?? injuryStomach,
        injuryShoulder: v['injuryShoulder'] ?? injuryShoulder,
        injuryRightHand: v['injuryRightHand'] ?? injuryRightHand,
        injuryLeftHand: v['injuryLeftHand'] ?? injuryLeftHand,
        injuryRightLeg: v['injuryRightLeg'] ?? injuryRightLeg,
        injuryLeftLeg: v['injuryLeftLeg'] ?? injuryLeftLeg,
        injuryPrivateParts: v['injuryPrivateParts'] ?? injuryPrivateParts,
        injuryBack: v['injuryBack'] ?? injuryBack,
        injuryOther: v['injuryOther'] ?? injuryOther,
        nostrils: v['nostrils'] ?? nostrils,
        earsEyes: v['earsEyes'] ?? earsEyes,
        mouth: v['mouth'] ?? mouth,
        penisVagina: v['penisVagina'] ?? penisVagina,
        anus: v['anus'] ?? anus,
        weaponOpinion: v['weaponOpinion'] ?? weaponOpinion,
        ligatureDescription: v['ligatureDescription'] ?? ligatureDescription,
        foreignMaterial: v['foreignMaterial'] ?? foreignMaterial,
        poDescription: v['poDescription'] ?? poDescription,
        articlesAtPo: v['articlesAtPo'] ?? articlesAtPo,
        probableCauseOfDeath: v['probableCauseOfDeath'] ?? probableCauseOfDeath,
        remarks: v['remarks'] ?? remarks,
        witness1NameAddress: v['witness1NameAddress'] ?? witness1NameAddress,
        witness2NameAddress: v['witness2NameAddress'] ?? witness2NameAddress,
        briefFacts: v['briefFacts'] ?? briefFacts,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'district': district,
        'policeStation': policeStation,
        'udNo': udNo,
        'gdeNo': gdeNo,
        'dateTime': dateTime,
        'distanceFromPs': distanceFromPs,
        'directionFromPs': directionFromPs,
        'placeFound': placeFound,
        'longitude': longitude,
        'latitude': latitude,
        'deadBodyFoundDate': deadBodyFoundDate,
        'deadBodyFoundTime': deadBodyFoundTime,
        'informantName': informantName,
        'informantAge': informantAge,
        'informantSex': informantSex,
        'informantAddress': informantAddress,
        'identifiedByName': identifiedByName,
        'identifiedByAge': identifiedByAge,
        'identifiedBySex': identifiedBySex,
        'identifiedByRelation': identifiedByRelation,
        'identifiedByAddress': identifiedByAddress,
        'deceasedName': deceasedName,
        'deceasedSex': deceasedSex,
        'deceasedAge': deceasedAge,
        'deceasedAddress': deceasedAddress,
        'bodyPosition': bodyPosition,
        'build': build,
        'height': height,
        'rigorMortis': rigorMortis,
        'complexion': complexion,
        'deformities': deformities,
        'religionRaceCommunity': religionRaceCommunity,
        'teeth': teeth,
        'eyes': eyes,
        'laceDerma': laceDerma,
        'mole': mole,
        'tattoo': tattoo,
        'dress': dress,
        'otherFeatures': otherFeatures,
        'injuryHead': injuryHead,
        'injuryFace': injuryFace,
        'injuryNeck': injuryNeck,
        'injuryChest': injuryChest,
        'injuryStomach': injuryStomach,
        'injuryShoulder': injuryShoulder,
        'injuryRightHand': injuryRightHand,
        'injuryLeftHand': injuryLeftHand,
        'injuryRightLeg': injuryRightLeg,
        'injuryLeftLeg': injuryLeftLeg,
        'injuryPrivateParts': injuryPrivateParts,
        'injuryBack': injuryBack,
        'injuryOther': injuryOther,
        'nostrils': nostrils,
        'earsEyes': earsEyes,
        'mouth': mouth,
        'penisVagina': penisVagina,
        'anus': anus,
        'weaponOpinion': weaponOpinion,
        'ligatureDescription': ligatureDescription,
        'foreignMaterial': foreignMaterial,
        'poDescription': poDescription,
        'articlesAtPo': articlesAtPo,
        'probableCauseOfDeath': probableCauseOfDeath,
        'remarks': remarks,
        'witness1NameAddress': witness1NameAddress,
        'witness2NameAddress': witness2NameAddress,
        'briefFacts': briefFacts,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory UdCase.fromJson(Map<String, dynamic> json) => UdCase(
        id: json['id'] ?? 'ud_${DateTime.now().microsecondsSinceEpoch}',
        district: json['district'] ?? '',
        policeStation: json['policeStation'] ?? '',
        udNo: json['udNo'] ?? '',
        gdeNo: json['gdeNo'] ?? '',
        dateTime: json['dateTime'] ?? '',
        distanceFromPs: json['distanceFromPs'] ?? '',
        directionFromPs: json['directionFromPs'] ?? '',
        placeFound: json['placeFound'] ?? '',
        longitude: json['longitude'] ?? '',
        latitude: json['latitude'] ?? '',
        deadBodyFoundDate: json['deadBodyFoundDate'] ?? '',
        deadBodyFoundTime: json['deadBodyFoundTime'] ?? '',
        informantName: json['informantName'] ?? '',
        informantAge: json['informantAge'] ?? '',
        informantSex: json['informantSex'] ?? '',
        informantAddress: json['informantAddress'] ?? '',
        identifiedByName: json['identifiedByName'] ?? '',
        identifiedByAge: json['identifiedByAge'] ?? '',
        identifiedBySex: json['identifiedBySex'] ?? '',
        identifiedByRelation: json['identifiedByRelation'] ?? '',
        identifiedByAddress: json['identifiedByAddress'] ?? '',
        deceasedName: json['deceasedName'] ?? '',
        deceasedSex: json['deceasedSex'] ?? '',
        deceasedAge: json['deceasedAge'] ?? '',
        deceasedAddress: json['deceasedAddress'] ?? '',
        bodyPosition: json['bodyPosition'] ?? '',
        build: json['build'] ?? '',
        height: json['height'] ?? '',
        rigorMortis: json['rigorMortis'] ?? '',
        complexion: json['complexion'] ?? '',
        deformities: json['deformities'] ?? '',
        religionRaceCommunity: json['religionRaceCommunity'] ?? '',
        teeth: json['teeth'] ?? '',
        eyes: json['eyes'] ?? '',
        laceDerma: json['laceDerma'] ?? '',
        mole: json['mole'] ?? '',
        tattoo: json['tattoo'] ?? '',
        dress: json['dress'] ?? '',
        otherFeatures: json['otherFeatures'] ?? '',
        injuryHead: json['injuryHead'] ?? '',
        injuryFace: json['injuryFace'] ?? '',
        injuryNeck: json['injuryNeck'] ?? '',
        injuryChest: json['injuryChest'] ?? '',
        injuryStomach: json['injuryStomach'] ?? '',
        injuryShoulder: json['injuryShoulder'] ?? '',
        injuryRightHand: json['injuryRightHand'] ?? '',
        injuryLeftHand: json['injuryLeftHand'] ?? '',
        injuryRightLeg: json['injuryRightLeg'] ?? '',
        injuryLeftLeg: json['injuryLeftLeg'] ?? '',
        injuryPrivateParts: json['injuryPrivateParts'] ?? '',
        injuryBack: json['injuryBack'] ?? '',
        injuryOther: json['injuryOther'] ?? '',
        nostrils: json['nostrils'] ?? '',
        earsEyes: json['earsEyes'] ?? '',
        mouth: json['mouth'] ?? '',
        penisVagina: json['penisVagina'] ?? '',
        anus: json['anus'] ?? '',
        weaponOpinion: json['weaponOpinion'] ?? '',
        ligatureDescription: json['ligatureDescription'] ?? '',
        foreignMaterial: json['foreignMaterial'] ?? '',
        poDescription: json['poDescription'] ?? '',
        articlesAtPo: json['articlesAtPo'] ?? '',
        probableCauseOfDeath: json['probableCauseOfDeath'] ?? '',
        remarks: json['remarks'] ?? '',
        witness1NameAddress: json['witness1NameAddress'] ?? '',
        witness2NameAddress: json['witness2NameAddress'] ?? '',
        briefFacts: json['briefFacts'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );
}
