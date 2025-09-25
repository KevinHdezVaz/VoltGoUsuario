// data/models/StripePlan.dart

import 'dart:convert';

// ✅ FUNCIÓN CORREGIDA para parsear la lista de planes
List<StripePlan> stripePlanFromJson(String str) {
  final jsonData = json.decode(str);
  
  // Manejar diferentes formatos de respuesta del backend
  List<dynamic> plansJson;
  
  if (jsonData is Map<String, dynamic>) {
    // Si el backend devuelve: {"success": true, "plans": [...]}
    if (jsonData.containsKey('plans')) {
      plansJson = jsonData['plans'] as List<dynamic>;
    } else if (jsonData.containsKey('data')) {
      plansJson = jsonData['data'] as List<dynamic>;
    } else {
      throw Exception('Formato de respuesta inesperado');
    }
  } else if (jsonData is List<dynamic>) {
    // Si el backend devuelve directamente el array: [...]
    plansJson = jsonData;
  } else {
    throw Exception('Formato de respuesta inesperado');
  }

  return plansJson.map((json) => StripePlan.fromJson(json)).toList();
}

String stripePlanToJson(List<StripePlan> data) =>
    json.encode(data.map((x) => x.toJson()).toList());

class StripePlan {
  final String priceId;
  final String productName;
  final String? productDescription;
  final String currency;
  final double amount;
  final String interval; // "month", "year", "one_time"
  final String? productId;
  final bool? productActive;
  final bool? priceActive;

  StripePlan({
    required this.priceId,
    required this.productName,
    this.productDescription,
    required this.currency,
    required this.amount,
    required this.interval,
    this.productId,
    this.productActive,
    this.priceActive,
  });

  // ✅ FACTORY CONSTRUCTOR CORREGIDO
  factory StripePlan.fromJson(Map<String, dynamic> json) {
    return StripePlan(
      priceId: json['price_id'] as String,
      productName: json['product_name'] as String,
      productDescription: json['product_description'] as String?,
      currency: json['currency'] as String,
      amount: (json['amount'] as num).toDouble(),
      interval: json['interval'] as String,
      productId: json['product_id'] as String?,
      productActive: json['product_active'] as bool?,
      priceActive: json['price_active'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'price_id': priceId,
      'product_name': productName,
      'product_description': productDescription,
      'currency': currency,
      'amount': amount,
      'interval': interval,
      'product_id': productId,
      'product_active': productActive,
      'price_active': priceActive,
    };
  }

  // ✅ MÉTODOS AUXILIARES ÚTILES
  bool get isMonthly => interval == 'month';
  bool get isYearly => interval == 'year';
  bool get isOneTime => interval == 'one_time';
  
  String get formattedAmount => '${amount.toStringAsFixed(2)} ${currency.toUpperCase()}';
  
  String get displayName {
    if (isOneTime) {
      return '$productName - $formattedAmount';
    } else {
      return '$productName - $formattedAmount/$interval';
    }
  }

  @override
  String toString() {
    return 'StripePlan(priceId: $priceId, productName: $productName, amount: $amount, interval: $interval)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StripePlan && other.priceId == priceId;
  }

  @override
  int get hashCode => priceId.hashCode;
} 