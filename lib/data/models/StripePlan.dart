// data/models/stripe_plan_model.dart

import 'dart:convert';

// Helper para decodificar el JSON de la lista de planes
List<StripePlan> stripePlanFromJson(String str) => List<StripePlan>.from(json.decode(str).map((x) => StripePlan.fromJson(x)));

class StripePlan {
    final String priceId;
    final String productName;
    final String? productDescription;
    final String currency;
    final double amount;
    final String interval;

    StripePlan({
        required this.priceId,
        required this.productName,
        this.productDescription,
        required this.currency,
        required this.amount,
        required this.interval,
    });

    factory StripePlan.fromJson(Map<String, dynamic> json) => StripePlan(
        priceId: json["price_id"],
        productName: json["product_name"],
        productDescription: json["product_description"],
        currency: json["currency"],
        amount: json["amount"]?.toDouble(),
        interval: json["interval"],
    );
}