import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class LicensePurchasePlan {
  final String planId;
  final String label;
  final int amountPaise;
  final String currency;

  const LicensePurchasePlan({
    required this.planId,
    required this.label,
    required this.amountPaise,
    required this.currency,
  });

  String get displayPrice {
    if (currency.toUpperCase() == 'INR') {
      final rupees = amountPaise / 100;
      return rupees == rupees.roundToDouble()
          ? '₹${rupees.toInt()}'
          : '₹${rupees.toStringAsFixed(2)}';
    }
    return '$currency ${(amountPaise / 100).toStringAsFixed(2)}';
  }

  factory LicensePurchasePlan.fromJson(Map<String, dynamic> json) {
    return LicensePurchasePlan(
      planId: (json['planId'] ?? '').toString(),
      label: (json['label'] ?? 'Yearly License').toString(),
      amountPaise: int.tryParse((json['amountPaise'] ?? '0').toString()) ?? 0,
      currency: (json['currency'] ?? 'INR').toString(),
    );
  }
}

class LicenseCheckout {
  final String orderId;
  final Uri checkoutUrl;

  const LicenseCheckout({
    required this.orderId,
    required this.checkoutUrl,
  });
}

class LicensePaymentStatus {
  final bool paid;
  final String message;
  final String? activationToken;

  const LicensePaymentStatus({
    required this.paid,
    required this.message,
    this.activationToken,
  });
}

class LicensePurchaseService {
  static const String product = 'INVESTIGO';

  static const String _baseUrl = String.fromEnvironment(
    'INVESTIGO_LICENSE_API_BASE_URL',
    defaultValue: '',
  );

  final http.Client _client;

  LicensePurchaseService({http.Client? client})
      : _client = client ?? http.Client();

  bool get isConfigured => _baseUrl.trim().isNotEmpty;

  Uri _uri(String path) {
    final base = _baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    if (base.isEmpty) {
      throw StateError('Online license purchase is not configured.');
    }
    return Uri.parse('$base$path');
  }

  Future<LicensePurchasePlan> fetchPlan() async {
    final response = await _client
        .get(_uri('/v1/products/$product/plan'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw StateError('Could not load license price.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Invalid license plan response.');
    }
    return LicensePurchasePlan.fromJson(decoded);
  }

  Future<LicenseCheckout> createCheckout({
    required String deviceCode,
    required String planId,
  }) async {
    final response = await _client
        .post(
          _uri('/v1/checkout'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'product': product,
            'deviceCode': deviceCode,
            'planId': planId,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Could not start payment. Please try again.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Invalid checkout response.');
    }

    final orderId = (decoded['orderId'] ?? '').toString();
    final checkoutUrl = Uri.tryParse((decoded['checkoutUrl'] ?? '').toString());

    if (orderId.isEmpty || checkoutUrl == null || !checkoutUrl.hasScheme) {
      throw StateError('Checkout information is incomplete.');
    }

    return LicenseCheckout(orderId: orderId, checkoutUrl: checkoutUrl);
  }

  Future<bool> openCheckout(LicenseCheckout checkout) {
    return launchUrl(
      checkout.checkoutUrl,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<LicensePaymentStatus> checkPayment({
    required String orderId,
    required String deviceCode,
  }) async {
    final response = await _client
        .post(
          _uri('/v1/checkout/status'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'product': product,
            'orderId': orderId,
            'deviceCode': deviceCode,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Could not verify payment. Please try again.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Invalid payment verification response.');
    }

    final paid = decoded['paid'] == true;
    final token = decoded['activationToken']?.toString().trim();

    return LicensePaymentStatus(
      paid: paid,
      message: (decoded['message'] ??
              (paid ? 'Payment verified.' : 'Payment not completed yet.'))
          .toString(),
      activationToken: token == null || token.isEmpty ? null : token,
    );
  }
}
