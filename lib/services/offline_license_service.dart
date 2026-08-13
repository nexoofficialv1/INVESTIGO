import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OfflineLicenseState { trial, licensed, expired, clockError }

class OfflineLicenseSnapshot {
  final OfflineLicenseState state;
  final String deviceCode;
  final DateTime trialStartedAt;
  final DateTime trialEndsAt;
  final DateTime? licenseExpiresAt;
  final String? licenseId;
  final String? customer;
  final int daysRemaining;
  final String detail;

  const OfflineLicenseSnapshot({
    required this.state,
    required this.deviceCode,
    required this.trialStartedAt,
    required this.trialEndsAt,
    required this.licenseExpiresAt,
    required this.licenseId,
    required this.customer,
    required this.daysRemaining,
    required this.detail,
  });

  bool get canUseApp =>
      state == OfflineLicenseState.trial ||
      state == OfflineLicenseState.licensed;

  bool get isLicensed => state == OfflineLicenseState.licensed;
}

class LicenseActivationResult {
  final bool success;
  final String message;
  final OfflineLicenseSnapshot? snapshot;

  const LicenseActivationResult({
    required this.success,
    required this.message,
    this.snapshot,
  });
}

class OfflineLicenseService {
  static const int trialDays = 14;
  static const String product = 'INVESTIGO';

  // Ed25519 public verification key only. The private signing key must never
  // be shipped in the application or committed to the repository.
  static const String _publicKeyBase64 =
      't8F+Kp9KxrdhIFIq+PFhjPJLjBY6U7POYODwcpLRvSU=';

  static const String _deviceKey = 'offline_license_device_code_v209';
  static const String _trialStartKey = 'offline_license_trial_start_v209';
  static const String _lastSeenKey = 'offline_license_last_seen_v209';
  static const String _tokenKey = 'offline_license_token_v209';

  static const Duration _clockRollbackTolerance = Duration(minutes: 10);

  Future<String> currentDeviceCode() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceKey)?.trim() ?? '';
    if (existing.isNotEmpty) return existing;

    final random = Random.secure();
    final seed = List<int>.generate(24, (_) => random.nextInt(256));
    final digest = await Sha256().hash(seed);
    final hex = digest.bytes
        .take(12)
        .map((e) => e.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
    final code =
        'INV-${hex.substring(0, 8)}-${hex.substring(8, 16)}-${hex.substring(16, 24)}';
    await prefs.setString(_deviceKey, code);
    return code;
  }

  Future<OfflineLicenseSnapshot> evaluate({DateTime? nowUtc}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    final deviceCode = await currentDeviceCode();

    var trialStartMs = prefs.getInt(_trialStartKey);
    if (trialStartMs == null) {
      trialStartMs = now.millisecondsSinceEpoch;
      await prefs.setInt(_trialStartKey, trialStartMs);
    }
    final trialStart =
        DateTime.fromMillisecondsSinceEpoch(trialStartMs, isUtc: true);
    final trialEnd = trialStart.add(const Duration(days: trialDays));

    final lastSeenMs = prefs.getInt(_lastSeenKey);
    if (lastSeenMs != null) {
      final lastSeen =
          DateTime.fromMillisecondsSinceEpoch(lastSeenMs, isUtc: true);
      if (now.isBefore(lastSeen.subtract(_clockRollbackTolerance))) {
        return OfflineLicenseSnapshot(
          state: OfflineLicenseState.clockError,
          deviceCode: deviceCode,
          trialStartedAt: trialStart,
          trialEndsAt: trialEnd,
          licenseExpiresAt: null,
          licenseId: null,
          customer: null,
          daysRemaining: 0,
          detail:
              'System date/time appears to have moved backwards. Correct the device date/time and reopen INVESTIGO.',
        );
      }
    }
    if (lastSeenMs == null || now.millisecondsSinceEpoch > lastSeenMs) {
      await prefs.setInt(_lastSeenKey, now.millisecondsSinceEpoch);
    }

    final token = prefs.getString(_tokenKey)?.trim() ?? '';
    if (token.isNotEmpty) {
      final verified = await _verifyToken(
        token,
        expectedDeviceCode: deviceCode,
      );
      if (verified != null) {
        if (now.isBefore(verified.expiresAt) ||
            now.isAtSameMomentAs(verified.expiresAt)) {
          return OfflineLicenseSnapshot(
            state: OfflineLicenseState.licensed,
            deviceCode: deviceCode,
            trialStartedAt: trialStart,
            trialEndsAt: trialEnd,
            licenseExpiresAt: verified.expiresAt,
            licenseId: verified.licenseId,
            customer: verified.customer,
            daysRemaining: _remainingDays(verified.expiresAt, now),
            detail: 'Yearly offline license verified.',
          );
        }
        return OfflineLicenseSnapshot(
          state: OfflineLicenseState.expired,
          deviceCode: deviceCode,
          trialStartedAt: trialStart,
          trialEndsAt: trialEnd,
          licenseExpiresAt: verified.expiresAt,
          licenseId: verified.licenseId,
          customer: verified.customer,
          daysRemaining: 0,
          detail: 'The installed yearly license has expired. Renew to continue.',
        );
      }
    }

    if (now.isBefore(trialEnd)) {
      return OfflineLicenseSnapshot(
        state: OfflineLicenseState.trial,
        deviceCode: deviceCode,
        trialStartedAt: trialStart,
        trialEndsAt: trialEnd,
        licenseExpiresAt: null,
        licenseId: null,
        customer: null,
        daysRemaining: _remainingDays(trialEnd, now),
        detail: '14-day offline trial is active.',
      );
    }

    return OfflineLicenseSnapshot(
      state: OfflineLicenseState.expired,
      deviceCode: deviceCode,
      trialStartedAt: trialStart,
      trialEndsAt: trialEnd,
      licenseExpiresAt: null,
      licenseId: null,
      customer: null,
      daysRemaining: 0,
      detail: 'The 14-day trial has ended. Activate a yearly license.',
    );
  }

  Future<LicenseActivationResult> activate(
    String rawToken, {
    DateTime? nowUtc,
  }) async {
    final token = rawToken.trim();
    if (token.isEmpty) {
      return const LicenseActivationResult(
        success: false,
        message: 'Activation key is empty.',
      );
    }

    final now = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    final deviceCode = await currentDeviceCode();
    final verified = await _verifyToken(
      token,
      expectedDeviceCode: deviceCode,
    );

    if (verified == null) {
      return const LicenseActivationResult(
        success: false,
        message:
            'Invalid activation key or this key belongs to another installation.',
      );
    }

    if (verified.expiresAt.isBefore(now)) {
      return const LicenseActivationResult(
        success: false,
        message: 'This activation key has already expired.',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_lastSeenKey, now.millisecondsSinceEpoch);
    final snapshot = await evaluate(nowUtc: now);

    return LicenseActivationResult(
      success: snapshot.isLicensed,
      message: snapshot.isLicensed
          ? 'License activated successfully.'
          : snapshot.detail,
      snapshot: snapshot,
    );
  }

  Future<_VerifiedLicense?> _verifyToken(
    String token, {
    required String expectedDeviceCode,
  }) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3 || parts[0] != 'INV1') return null;

      final payloadPart = parts[1];
      final signaturePart = parts[2];
      final payloadBytes = _decodeBase64Url(payloadPart);
      final signatureBytes = _decodeBase64Url(signaturePart);
      final decoded = jsonDecode(utf8.decode(payloadBytes));
      if (decoded is! Map<String, dynamic>) return null;

      final publicKey = SimplePublicKey(
        base64.decode(_publicKeyBase64),
        type: KeyPairType.ed25519,
      );
      final signature = Signature(
        signatureBytes,
        publicKey: publicKey,
      );
      final signedMessage = utf8.encode('INV1.$payloadPart');
      final valid = await Ed25519().verify(
        signedMessage,
        signature: signature,
      );
      if (!valid) return null;

      final tokenProduct = decoded['product']?.toString() ?? '';
      final deviceCode = decoded['deviceCode']?.toString() ?? '';
      final licenseId = decoded['licenseId']?.toString() ?? '';
      final customer = decoded['customer']?.toString() ?? '';
      final expiresAtRaw = decoded['expiresAt']?.toString() ?? '';
      final expiresAt = DateTime.tryParse(expiresAtRaw)?.toUtc();

      if (tokenProduct != product ||
          deviceCode != expectedDeviceCode ||
          licenseId.isEmpty ||
          expiresAt == null) {
        return null;
      }

      return _VerifiedLicense(
        licenseId: licenseId,
        customer: customer,
        expiresAt: expiresAt,
      );
    } catch (_) {
      return null;
    }
  }

  static List<int> _decodeBase64Url(String value) {
    final missing = (4 - value.length % 4) % 4;
    return base64Url.decode(value.padRight(value.length + missing, '='));
  }

  static int _remainingDays(DateTime until, DateTime now) {
    final seconds = until.difference(now).inSeconds;
    if (seconds <= 0) return 0;
    return (seconds / Duration.secondsPerDay).ceil();
  }
}

class _VerifiedLicense {
  final String licenseId;
  final String customer;
  final DateTime expiresAt;

  const _VerifiedLicense({
    required this.licenseId,
    required this.customer,
    required this.expiresAt,
  });
}
