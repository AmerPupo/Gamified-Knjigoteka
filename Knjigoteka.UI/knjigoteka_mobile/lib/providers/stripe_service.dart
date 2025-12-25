import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:knjigoteka_mobile/providers/auth_provider.dart';

class StripeService {
  static String _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: "http://10.0.2.2:7295/api",
  );

  static Map<String, String> getHeaders() {
    final token = AuthProvider.token;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<void> init() async {
    final publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
    if (publishableKey == null || publishableKey.isEmpty) {
      throw Exception('Stripe publishable key not found in .env');
    }
    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
  }

  static Future<Map<String, dynamic>?> createPaymentIntent(
    double amount, {
    required String currency,
  }) async {
    try {
      final cents = (amount * 100).round();
      final res = await http
          .post(
            Uri.parse('$_baseUrl/Stripe/create-payment-intent'),
            headers: getHeaders(),
            body: json.encode({'amount': cents, 'currency': currency}),
          )
          .timeout(const Duration(seconds: 25));

      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      } else {
        debugPrint('PI create failed: ${res.statusCode} ${res.body}');
        return null;
      }
    } on TimeoutException {
      debugPrint('PI create timeout');
      return null;
    } catch (e) {
      debugPrint('Exception creating PI: $e');
      return null;
    }
  }

  static Future<bool> processPayment({
    required double amount,
    required String currency,
  }) async {
    try {
      final data = await createPaymentIntent(amount, currency: currency);
      if (data == null || data['clientSecret'] == null) {
        throw Exception('Failed to create payment intent');
      }
      final clientSecret = data['clientSecret'] as String;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Leami Shop',
          style: ThemeMode.dark,
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        debugPrint('User canceled payment sheet.');
        return false;
      }
      throw Exception('Payment failed: ${e.error.localizedMessage}');
    } on TimeoutException {
      throw Exception('Stripe operation timed out.');
    } catch (e) {
      throw Exception('Payment failed: $e');
    }
  }

  static Future<Map<String, dynamic>?> createCheckoutSession({
    required double amount,
    required String productName,
    String currency = 'usd',
  }) async {
    try {
      final amountInCents = (amount * 100).round();
      final res = await http
          .post(
            Uri.parse('$_baseUrl/Stripe/create-checkout-session'),
            headers: getHeaders(),
            body: json.encode({
              'amount': amountInCents,
              'productName': productName,
              'currency': currency,
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      } else {
        debugPrint('Checkout session failed: ${res.statusCode} ${res.body}');
        return null;
      }
    } on TimeoutException {
      debugPrint('Checkout session timeout');
      return null;
    } catch (e) {
      debugPrint('Exception creating checkout session: $e');
      return null;
    }
  }
}
