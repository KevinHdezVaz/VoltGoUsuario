// utils/stripe_config.dart
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeConfig {
  static const String publishableKey = 'pk_test_51S5rsnRvGQ4EcXpDnIgoFsG2t5CfRMwm83npFe5eoOJm2pTFlxOioqssGzB7ThQYfkPD8wnKMuN8s7GXpWGwppK600PMutdUI2'; // Tu clave pública de Stripe
  
  static Future<void> initialize() async {
    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
  }
}