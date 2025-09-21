// lib/data/models/UserSubscription.dart

class UserSubscription {
  final int? id;
  final int userId;
  final String? subscriptionId;           // stripe_subscription_id
  final String? stripePaymentIntentId;    // stripe_payment_intent_id
  final String stripePriceId;
  final String planType;                  // 'monthly' or 'one_time'
  final String? planName;
  final String? planDescription;
  final double amount;
  final String currency;
  final bool isActive;
  final int? remainingServices;           // ✅ CLAVE: Servicios restantes
  final DateTime? expiresAt;
  final DateTime? purchasedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserSubscription({
    this.id,
    required this.userId,
    this.subscriptionId,
    this.stripePaymentIntentId,
    required this.stripePriceId,
    required this.planType,
    this.planName,
    this.planDescription,
    required this.amount,
    required this.currency,
    required this.isActive,
    this.remainingServices,
    this.expiresAt,
    this.purchasedAt,
    this.createdAt,
    this.updatedAt,
  });

  // ✅ Factory constructor desde JSON con manejo seguro de tipos
  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'],
      userId: json['user_id'],
      subscriptionId: json['stripe_subscription_id'],
      stripePaymentIntentId: json['stripe_payment_intent_id'],
      stripePriceId: json['stripe_price_id'],
      planType: json['plan_type'],
      planName: json['plan_name'],
      planDescription: json['plan_description'],
      // ✅ CORREGIDO: Manejo seguro del campo amount
      amount: _parseDouble(json['amount']),
      currency: json['currency'],
      isActive: json['is_active'] == true || json['is_active'] == 1,
      remainingServices: json['remaining_services'],
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      purchasedAt: json['purchased_at'] != null ? DateTime.parse(json['purchased_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  // ✅ NUEVO: Helper para parsear doubles de forma segura
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    
    return 0.0;
  }

  // ✅ Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'stripe_subscription_id': subscriptionId,
      'stripe_payment_intent_id': stripePaymentIntentId,
      'stripe_price_id': stripePriceId,
      'plan_type': planType,
      'plan_name': planName,
      'plan_description': planDescription,
      'amount': amount,
      'currency': currency,
      'is_active': isActive,
      'remaining_services': remainingServices,
      'expires_at': expiresAt?.toIso8601String(),
      'purchased_at': purchasedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ✅ Métodos de utilidad (igual que en el backend)
  bool canUseService() {
    if (!isActive) return false;

    if (planType == 'monthly') {
      // Verificar expiración
      if (expiresAt != null && expiresAt!.isBefore(DateTime.now())) {
        return false;
      }
      
      // Si tiene límite de servicios, verificar que queden
      if (remainingServices != null) {
        return remainingServices! > 0;
      }
      
      // Si no tiene límite (null), es ilimitado
      return true;
    }
    
    if (planType == 'one_time') {
      return (remainingServices ?? 0) > 0;
    }
    
    return false;
  }

  bool isExpired() {
    if (planType == 'monthly' && expiresAt != null) {
      return expiresAt!.isBefore(DateTime.now());
    }
    
    if (planType == 'one_time') {
      return (remainingServices ?? 0) <= 0;
    }
    
    return false;
  }

  // ✅ Calcular próxima fecha de reset para planes mensuales
  DateTime? getNextResetDate() {
    if (planType != 'monthly' || purchasedAt == null) {
      return null;
    }

    final purchase = purchasedAt!;
    final now = DateTime.now();
    
    // Calcular cuántos meses han pasado
    int monthsPassed = ((now.year - purchase.year) * 12) + (now.month - purchase.month);
    
    // Si aún no ha pasado el día de compra este mes, usar el mes actual
    if (now.day < purchase.day) {
      monthsPassed--;
    }
    
    // Próxima fecha de reset
    return DateTime(
      purchase.year,
      purchase.month + monthsPassed + 1,
      purchase.day,
    );
  }

  // ✅ Días hasta el próximo reset
  int? getDaysUntilReset() {
    final nextReset = getNextResetDate();
    if (nextReset == null) return null;
    
    final difference = nextReset.difference(DateTime.now()).inDays;
    return difference > 0 ? difference : 0;
  }

  // ✅ Método para copiar con nuevos valores
  UserSubscription copyWith({
    int? id,
    int? userId,
    String? subscriptionId,
    String? stripePaymentIntentId,
    String? stripePriceId,
    String? planType,
    String? planName,
    String? planDescription,
    double? amount,
    String? currency,
    bool? isActive,
    int? remainingServices,
    DateTime? expiresAt,
    DateTime? purchasedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSubscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
      stripePriceId: stripePriceId ?? this.stripePriceId,
      planType: planType ?? this.planType,
      planName: planName ?? this.planName,
      planDescription: planDescription ?? this.planDescription,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      remainingServices: remainingServices ?? this.remainingServices,
      expiresAt: expiresAt ?? this.expiresAt,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserSubscription{id: $id, planType: $planType, planName: $planName, amount: $amount, isActive: $isActive, remainingServices: $remainingServices}';
  }
}