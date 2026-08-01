class BackendConfig {
  final String mode; // offline, custom_server, supabase
  final String apiBaseUrl;
  final String apiToken;
  final String fileUploadUrl;
  final bool syncEnabled;
  final DateTime? lastTestedAt;
  final String lastStatus;

  const BackendConfig({
    this.mode = 'offline',
    this.apiBaseUrl = '',
    this.apiToken = '',
    this.fileUploadUrl = '',
    this.syncEnabled = false,
    this.lastTestedAt,
    this.lastStatus = 'Offline only',
  });

  bool get isCustomServer => mode == 'custom_server';
  bool get isSupabase => mode == 'supabase';
  bool get isOnlineEnabled => mode != 'offline' && syncEnabled;

  BackendConfig copyWith({
    String? mode,
    String? apiBaseUrl,
    String? apiToken,
    String? fileUploadUrl,
    bool? syncEnabled,
    DateTime? lastTestedAt,
    String? lastStatus,
  }) {
    return BackendConfig(
      mode: mode ?? this.mode,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      apiToken: apiToken ?? this.apiToken,
      fileUploadUrl: fileUploadUrl ?? this.fileUploadUrl,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      lastTestedAt: lastTestedAt ?? this.lastTestedAt,
      lastStatus: lastStatus ?? this.lastStatus,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'apiBaseUrl': apiBaseUrl,
        'apiToken': apiToken,
        'fileUploadUrl': fileUploadUrl,
        'syncEnabled': syncEnabled,
        'lastTestedAt': lastTestedAt?.toIso8601String(),
        'lastStatus': lastStatus,
      };

  factory BackendConfig.fromJson(Map<String, dynamic> json) {
    return BackendConfig(
      mode: json['mode']?.toString() ?? 'offline',
      apiBaseUrl: json['apiBaseUrl']?.toString() ?? '',
      apiToken: json['apiToken']?.toString() ?? '',
      fileUploadUrl: json['fileUploadUrl']?.toString() ?? '',
      syncEnabled: json['syncEnabled'] == true,
      lastTestedAt: json['lastTestedAt'] == null || json['lastTestedAt'].toString().isEmpty
          ? null
          : DateTime.tryParse(json['lastTestedAt'].toString()),
      lastStatus: json['lastStatus']?.toString() ?? 'Offline only',
    );
  }

  factory BackendConfig.empty() => const BackendConfig();
}
